import 'package:http/http.dart';
import 'package:mineral/src/domains/services/http/http.dart';

final class Request<T> implements RequestContract {
  @override
  RequestType type;

  @override
  String? method;

  @override
  dynamic body;

  @override
  List<MultipartFile> files;

  @override
  Set<Header> headers;

  @override
  Uri url;

  @override
  Map<String, String> queryParameters;

  Request({
    required this.type,
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
    required this.queryParameters,
    required this.files,
  });

  static Request json({
    required String endpoint,
    String? method,
    Set<Header>? headers,
    dynamic body,
    Map<String, String>? queryParameters,
  }) {
    return Request<Map<String, dynamic>>(
      type: RequestType.json,
      method: method,
      url: Uri.parse(endpoint),
      headers: {...headers ?? {}, Header.contentType('application/json')},
      body: body,
      queryParameters: queryParameters ?? {},
      files: [],
    );
  }

  static Request formData({
    required String endpoint,
    String? method,
    Set<Header>? headers,
    Map<String, dynamic>? body,
    List<MultipartFile>? files,
  }) {
    return Request<Map<String, dynamic>>(
      type: RequestType.formData,
      method: method,
      url: Uri.parse(endpoint),
      headers: {...headers ?? {}, Header.contentType('multipart/form-data')},
      body: body,
      queryParameters: {},
      files: files ?? [],
    );
  }

  static Request auto({
    required String endpoint,
    String? method,
    Set<Header>? headers,
    Map<String, dynamic>? body,
    List<MultipartFile> files = const [],
  }) {
    return switch (files.isEmpty) {
      true => Request.json(endpoint: endpoint, body: body, headers: headers),
      false => Request.formData(endpoint: endpoint, body: body, files: files),
    };
  }

  @override
  Request copyWith({
    String? method,
    Uri? url,
    Set<Header>? headers,
    Object? body,
    Map<String, String>? queryParameters,
    List<MultipartFile>? files,
  }) {
    return Request(
      type: type,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: {...this.headers, ...(headers ?? {})},
      body: body ?? this.body,
      queryParameters: {...this.queryParameters, ...(queryParameters ?? {})},
      files: files ?? this.files,
    );
  }
}
