import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/private/user.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';

final class UserPart extends BasePart implements UserPartContract {
  UserPart(super.marshaller, super.dataStore);

  @override
  Future<User?> get(Object id, bool force) async {
    final userId = Snowflake.parse(id);
    final String key = marshaller.cacheKey.user(userId.value);

    final cachedUser = await marshaller.cache?.get(key);
    if (!force && cachedUser != null) {
      final user = await marshaller.serializers.user.serialize(cachedUser);

      return user;
    }

    final request = Request.json(endpoint: '/users/$userId');
    final result = await dataStore.requestBucket
        .query<Map<String, dynamic>>(request)
        .run(dataStore.client.get);

    final raw = await marshaller.serializers.user.normalize(result);
    final user = await marshaller.serializers.user.serialize(raw);

    return user;
  }
}
