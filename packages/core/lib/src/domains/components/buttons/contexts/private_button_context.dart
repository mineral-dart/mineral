import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/components/buttons/button_context_base.dart';

final class PrivateButtonContext extends ButtonContextBase {
  DataStoreContract get _dataStore => ctx.datastore;

  final Snowflake? authorId;

  PrivateButtonContext({
    required super.id,
    required super.applicationId,
    required super.token,
    required super.version,
    required super.customId,
    required this.authorId,
    required super.channelId,
    required super.messageId,
    required super.ctx,
  });

  Future<User> resolveAuthor({bool force = false}) async {
    final author = await _dataStore.user.get(authorId!.value, force);
    return author!;
  }
}
