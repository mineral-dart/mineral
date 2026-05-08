import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';

abstract base class BasePart {
  final MarshallerContract marshaller;
  final DataStoreContract dataStore;

  BasePart(this.marshaller, this.dataStore);

  HttpClientStatus get status => dataStore.client.status;
}
