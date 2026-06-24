enum ResponseCode {
  success(200, 'The request is passed with success'),
  created(201, 'The request is created with success'),
  accepted(202, 'The request is accepted'),
  noContent(204, 'The request is passed with success but no content'),
  badRequest(400, 'The request is invalid'),
  unauthorized(401, 'The request is unauthorized'),
  forbidden(403, 'The request is forbidden'),
  notFound(404, 'The request is not found'),
  methodNotAllowed(405, 'The request method is not allowed'),
  rateLimit(429, 'The request is rate limited'),
  internalServerError(500, 'An internal server error occurred'),
  notImplemented(501, 'The request is not implemented'),
  badGateway(502, 'The request is invalid'),
  serviceUnavailable(503, 'The service is unavailable'),
  gatewayTimeout(504, 'The gateway is timeout'),
  unknown(0, 'An unknown error occurred');

  final int code;
  final String message;

  const ResponseCode(this.code, this.message);

  @override
  String toString() {
    return 'ResponseCode: $code - $message';
  }

  static List<ResponseCode> get errorsCodes => [
    badRequest,
    unauthorized,
    forbidden,
    notFound,
    methodNotAllowed,
    internalServerError,
    badGateway,
    serviceUnavailable,
    gatewayTimeout,
    unknown,
  ];

  static List<ResponseCode> get successCodes => [
    success,
    created,
    accepted,
    noContent,
  ];

  static List<ResponseCode> get rateLimitCodes => [rateLimit];
}
