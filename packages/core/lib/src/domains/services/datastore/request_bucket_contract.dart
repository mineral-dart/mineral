import 'package:mineral/services.dart';

/// Domain-layer contract for the HTTP request bucket.
///
/// Callers in the domain only need the five HTTP-verb helpers; concrete
/// infrastructure details (rate-limit registry, queuing) are hidden behind
/// this interface.
abstract interface class RequestBucketContract {
  Future<T> get<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  });

  Future<T> post<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  });

  Future<T> put<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  });

  Future<T> patch<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  });

  Future<T> delete<T>(
    RequestContract request, {
    void Function(T)? onSuccess,
    Exception Function(Response)? onError,
    void Function(Duration)? onRateLimit,
  });
}
