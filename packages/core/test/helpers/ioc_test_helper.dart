import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';

import 'fake_logger.dart';

export 'package:mineral/container.dart' show runWithIoc;

/// Creates a scoped IoC container for testing with a [FakeLogger] bound.
///
/// Pass a [dataStore] to also bind [DataStoreContract] — required when the
/// code under test reaches [QueueableRequest] (e.g. DataStore Part methods).
///
/// Returns a restore function to call in tearDown.
({IocContainer container, FakeLogger logger, void Function() restore})
createTestIoc({DataStoreContract? dataStore, MarshallerContract? marshaller}) {
  final logger = FakeLogger();
  final container = IocContainer()..bind<LoggerContract>(() => logger);
  if (dataStore != null) {
    container.bind<DataStoreContract>(() => dataStore);
  }
  if (marshaller != null) {
    container.bind<MarshallerContract>(() => marshaller);
  }
  final restore = scopedIoc(container);
  return (container: container, logger: logger, restore: restore);
}
