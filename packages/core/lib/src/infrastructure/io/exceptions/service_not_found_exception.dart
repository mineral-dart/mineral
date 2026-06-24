import 'package:mineral/src/infrastructure/io/exceptions/mineral_exception.dart';

final class ServiceNotFoundException extends RecoverableMineralException {
  final Type serviceType;

  ServiceNotFoundException(this.serviceType)
    : super(
        'Service "$serviceType" is not registered in the IoC container. '
        'Make sure you call container.bind<$serviceType>(...) before '
        'resolving it.',
      );
}
