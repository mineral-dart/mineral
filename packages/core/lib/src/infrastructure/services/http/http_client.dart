import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mineral/services.dart';

class HttpClient implements HttpClientContract {
  final http.Client _client = http.Client();

  @override
  final HttpClientStatus status = HttpClientStatusImpl();

  @override
  final HttpInterceptor interceptor = HttpInterceptorImpl();

  @override
  final HttpClientConfig config;

  HttpClient({required this.config}) {
    if (config.uri.scheme != 'https') {
      throw ArgumentError.value(
        config.uri,
        'config.uri',
        'HttpClient requires an https:// URI to protect bearer tokens in transit',
      );
    }
  }

  @override
  Future<Response<T>> get<T>(RequestContract request) async {
    return _request(request.copyWith(method: 'GET'));
  }

  @override
  Future<Response<T>> patch<T>(RequestContract request) async {
    return _request(request.copyWith(method: 'PATCH'));
  }

  @override
  Future<Response<T>> post<T>(RequestContract request) async {
    return _request(request.copyWith(method: 'POST'));
  }

  @override
  Future<Response<T>> put<T>(RequestContract request) async {
    return _request(request.copyWith(method: 'PUT'));
  }

  @override
  Future<Response<T>> delete<T>(RequestContract request) async {
    return _request(request.copyWith(method: 'DELETE'));
  }

  @override
  Future<Response<T>> send<T>(RequestContract request) async {
    if (request.method == null) {
      throw HttpException('Method is required');
    }

    return _request(request);
  }

  Future<Response<T>> _request<T>(RequestContract request) async {
    request.headers.addAll(config.headers);
    request.url = Uri(
      host: config.uri.host,
      scheme: config.uri.scheme,
      path:
          '${config.uri.path.endsWith('/') ? config.uri.path.substring(0, config.uri.path.length - 1) : config.uri.path}${request.url.path}',
      queryParameters: request.queryParameters,
    );

    for (final requestInterceptor in interceptor.request) {
      request = await requestInterceptor(request);
    }

    final req = switch (request.type) {
      RequestType.json =>
        http.Request(request.method!, request.url)
          ..headers.addAll(_serializeHeaders(request.headers))
          ..body = request.body != null ? jsonEncode(request.body) : '',
      RequestType.formData =>
        http.MultipartRequest(request.method!, request.url)
          ..headers.addAll(_serializeHeaders(request.headers))
          ..fields['payload_json'] = jsonEncode(request.body)
          ..files.addAll(request.files),
    };

    final http.StreamedResponse streamedResponse = await _client
        .send(req)
        .timeout(config.requestTimeout);
    final http.Response res = await http.Response.fromStream(streamedResponse);

    Response response = ResponseImpl.fromHttpResponse<T>(res);

    for (final handle in interceptor.response) {
      response = await handle(response);
    }

    return response as Response<T>;
  }

  Map<String, String> _serializeHeaders(Set<Header> headers) {
    return headers.fold(
      {},
      (previousValue, element) => {
        ...previousValue,
        element.key: element.value,
      },
    );
  }
}
