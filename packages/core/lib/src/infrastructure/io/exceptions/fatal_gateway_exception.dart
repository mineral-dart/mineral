import 'package:mineral/src/infrastructure/io/exceptions/mineral_exception.dart';

final class FatalGatewayException extends FatalMineralException {
  final int code;

  FatalGatewayException(String message, this.code)
    : super('Gateway error $code: $message');
}
