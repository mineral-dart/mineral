import 'package:http/http.dart' as http;
import 'package:mineral/services.dart';

abstract interface class HttpClientContract {
  HttpClientStatus get status;

  HttpInterceptor get interceptor;

  HttpClientConfig get config;

  Future<Response<T>> get<T>(RequestContract request);

  Future<Response<T>> post<T>(RequestContract request);

  Future<Response<T>> put<T>(RequestContract request);

  Future<Response<T>> patch<T>(RequestContract request);

  Future<Response<T>> delete<T>(RequestContract request);

  Future<Response<T>> send<T>(RequestContract request);
}

class Header {
  final String key;
  final String value;

  Header(this.key, this.value);

  Header.contentType(String value) : this('Content-Type', value);
  Header.accept(String value) : this('Accept', value);
  Header.authorization(String value) : this('Authorization', value);
  Header.userAgent(String value) : this('User-Agent', value);
}

enum RequestType { json, formData }

abstract interface class RequestContract {
  RequestType get type;

  String? method;

  late Uri url;

  Set<Header> get headers;

  Map<String, String> get queryParameters;

  Object? get body;

  List<http.MultipartFile> get files;

  RequestContract copyWith({
    String? method,
    Uri? url,
    Set<Header>? headers,
    Object? body,
    Map<String, String>? queryParameters,
  });
}
