import 'package:mineral/services.dart';

import 'fake_response.dart';

/// Configurable fake [HttpClientContract] for unit tests.
///
/// Feed it a list of outcomes (status codes, response bodies, or exceptions)
/// via the constructor. Each call to any HTTP verb pops the next entry.
/// If the list is exhausted, all subsequent calls return 200 with `{}`.
///
/// All calls are recorded in [calls] so tests can assert on them.
final class FakeHttpClient implements HttpClientContract {
  final List<Object> _outcomes;

  /// Records every call: `(method, path)` from the request URL.
  final List<({String method, String path})> calls = [];

  /// Records the full [RequestContract] for each call.
  final List<RequestContract> requests = [];

  FakeHttpClient([List<Object> outcomes = const []])
    : _outcomes = List.of(outcomes);

  @override
  HttpClientStatus get status => HttpClientStatusImpl();

  @override
  HttpInterceptor get interceptor => HttpInterceptorImpl();

  @override
  HttpClientConfig get config => throw UnimplementedError();

  Future<Response<T>> _dispatch<T>(
    String method,
    RequestContract request,
  ) async {
    calls.add((method: method, path: request.url.path));
    requests.add(request);

    final outcome = _outcomes.isEmpty ? 200 : _outcomes.removeAt(0);

    if (outcome is Exception) {
      throw outcome;
    }
    if (outcome is Error) {
      throw outcome;
    }
    if (outcome is Response<T>) {
      return outcome;
    }

    final statusCode = outcome as int;
    return FakeResponse<T>(statusCode, <String, dynamic>{} as T);
  }

  @override
  Future<Response<T>> get<T>(RequestContract r) => _dispatch<T>('GET', r);

  @override
  Future<Response<T>> post<T>(RequestContract r) => _dispatch<T>('POST', r);

  @override
  Future<Response<T>> put<T>(RequestContract r) => _dispatch<T>('PUT', r);

  @override
  Future<Response<T>> patch<T>(RequestContract r) => _dispatch<T>('PATCH', r);

  @override
  Future<Response<T>> delete<T>(RequestContract r) => _dispatch<T>('DELETE', r);

  @override
  Future<Response<T>> send<T>(RequestContract r) =>
      _dispatch<T>(r.method ?? 'SEND', r);
}
