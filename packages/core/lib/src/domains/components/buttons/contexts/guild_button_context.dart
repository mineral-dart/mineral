import 'package:mineral/src/domains/components/buttons/button_context_base.dart';

final class GuildButtonContext extends ButtonContextBase {
  GuildButtonContext({
    required super.id,
    required super.applicationId,
    required super.token,
    required super.version,
    required super.customId,
    required super.channelId,
    required super.messageId,
    required super.ctx,
  });
}
