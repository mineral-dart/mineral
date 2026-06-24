import 'package:mineral/services.dart';

final class DiscordHeader implements Header {
  @override
  final String key;

  @override
  final String value;

  DiscordHeader(this.key, this.value);

  DiscordHeader.contentType(String value) : this('Content-Type', value);
  DiscordHeader.accept(String value) : this('Accept', value);
  DiscordHeader.authorization(String value) : this('Authorization', value);
  DiscordHeader.userAgent(String value) : this('User-Agent', value);
  DiscordHeader.auditLogReason(String? value)
    : this('X-Audit-Log-Reason', Uri.encodeComponent(value ?? ''));
}
