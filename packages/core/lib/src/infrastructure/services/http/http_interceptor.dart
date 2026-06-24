import 'dart:async';

import 'package:mineral/services.dart';

typedef RequestInterceptor =
    FutureOr<RequestContract> Function(RequestContract);
typedef ResponseInterceptor = FutureOr<Response> Function(Response);

abstract interface class HttpInterceptor {
  List<RequestInterceptor> get request;

  List<ResponseInterceptor> get response;
}

final class HttpInterceptorImpl implements HttpInterceptor {
  @override
  final List<RequestInterceptor> request = [];

  @override
  final List<ResponseInterceptor> response = [];
}
