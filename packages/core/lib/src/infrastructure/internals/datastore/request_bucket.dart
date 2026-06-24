import 'dart:async';
import 'dart:io';

import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/services/datastore/request_bucket_contract.dart';
import 'package:mineral/src/infrastructure/internals/datastore/rate_limit_registry.dart';
import 'package:mineral/src/infrastructure/internals/datastore/route_key.dart';

typedef RequestAction<T> =
    Future<Response<T>> Function(RequestContract request);

enum QueueableRequestStatus { init, success, error, rateLimit, pending }

final class QueueableRequest<T> {
  static const int _maxRateLimitRetries = 5;

  LoggerContract get _logger => bucket.logger;

  final RequestBucket bucket;
  final Completer<T> completer;
  final RequestContract query;
  final String method;
  final RequestAction<T> request;

  DateTime? retryAt;
  QueueableRequestStatus status = QueueableRequestStatus.init;

  final Exception Function(Response)? _onError;
  final void Function(T)? _onSuccess;
  final void Function(Duration)? _onRateLimit;

  QueueableRequest(
    this.bucket,
    this.method,
    this.query,
    this.request,
    this.completer,
    this._onError,
    this._onSuccess,
    this._onRateLimit,
  );

  Future<void> execute() async {
    final route = RouteKey(method, query.url.path);
    final httpStatus = bucket.client.status;

    for (var attempt = 0; attempt < _maxRateLimitRetries; attempt++) {
      final delay = bucket.registry.delayFor(route);
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      status = QueueableRequestStatus.pending;
      final response = await request(query);

      bucket.registry.updateFromHeaders(route, response.headers);

      if (httpStatus.isSuccess(response.statusCode)) {
        status = QueueableRequestStatus.success;
        bucket.queue.remove(this);
        try {
          _onSuccess?.call(response.body);
          completer.complete(response.body);
          // ignore: avoid_catching_errors, surface type mismatch as a proper HttpException
        } on TypeError catch (e) {
          completer.completeError(
            HttpException(
              'Response body type mismatch: expected $T, '
              'got ${response.body.runtimeType}. $e',
            ),
          );
        }
        return;
      }

      if (httpStatus.isRateLimit(response.statusCode)) {
        final body = response.body;
        final isGlobal = body is Map && body['global'] == true;
        final retryAfter = body is Map ? body['retry_after'] : null;
        final seconds = retryAfter is num
            ? retryAfter.toDouble()
            : double.tryParse(retryAfter?.toString() ?? '') ?? 1.0;
        final retryDelay = Duration(
          milliseconds: (seconds * 1000).round() + 50,
        );

        if (isGlobal) {
          bucket.registry.lockGlobal(retryDelay);
        } else {
          bucket.registry.lockRoute(route, retryDelay);
        }

        _logger.warn(
          'Rate limit reached on ${route.redactedString} '
          '(attempt ${attempt + 1}/$_maxRateLimitRetries, '
          '${isGlobal ? 'global' : 'bucket'}). '
          'Retrying in ${retryDelay.inMilliseconds}ms',
        );

        status = QueueableRequestStatus.rateLimit;
        retryAt = DateTime.now().add(retryDelay);

        _onRateLimit?.call(retryDelay);
        await Future<void>.delayed(retryDelay);
        continue;
      }

      if (httpStatus.isError(response.statusCode)) {
        status = QueueableRequestStatus.error;
        bucket.queue.remove(this);
        final exception =
            _onError?.call(response) ?? HttpException(response.bodyString);
        completer.completeError(exception);
        return;
      }
    }

    status = QueueableRequestStatus.error;
    bucket.queue.remove(this);
    completer.completeError(
      HttpException('Rate limit retry cap ($_maxRateLimitRetries) reached'),
    );
  }
}

final class RequestBucket implements RequestBucketContract {
  final HttpClientContract client;
  final RateLimitRegistry registry;
  final LoggerContract logger;
  final List<QueueableRequest> queue = [];

  RequestBucket(
    this.client, {
    required this.logger,
    RateLimitRegistry? registry,
  }) : registry = registry ?? RateLimitRegistry();

  @override
  Future<T> get<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  }) => _send<T>(
    'GET',
    request,
    client.get,
    onSuccess: onSuccess,
    onError: onError,
    onRateLimit: onRateLimit,
  );

  @override
  Future<T> post<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  }) => _send<T>(
    'POST',
    request,
    client.post,
    onSuccess: onSuccess,
    onError: onError,
    onRateLimit: onRateLimit,
  );

  @override
  Future<T> put<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  }) => _send<T>(
    'PUT',
    request,
    client.put,
    onSuccess: onSuccess,
    onError: onError,
    onRateLimit: onRateLimit,
  );

  @override
  Future<T> patch<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  }) => _send<T>(
    'PATCH',
    request,
    client.patch,
    onSuccess: onSuccess,
    onError: onError,
    onRateLimit: onRateLimit,
  );

  @override
  Future<T> delete<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  }) => _send<T>(
    'DELETE',
    request,
    client.delete,
    onSuccess: onSuccess,
    onError: onError,
    onRateLimit: onRateLimit,
  );

  Future<T> _send<T>(
    String method,
    RequestContract request,
    RequestAction<T> action, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  }) async {
    final completer = Completer<T>();
    final queueable = QueueableRequest<T>(
      this,
      method,
      request,
      action,
      completer,
      onError,
      onSuccess,
      onRateLimit,
    );
    queue.add(queueable);
    await queueable.execute();
    return completer.future;
  }
}
