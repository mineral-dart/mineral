import 'package:mineral/src/infrastructure/io/exceptions/mineral_exception.dart';

final class HttpStatusException extends RecoverableMineralException {
  final int statusCode;
  final String body;

  HttpStatusException(this.statusCode, this.body)
    : super('HTTP $statusCode: $body');
}
