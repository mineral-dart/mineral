import 'package:mineral/src/api/common/embed/message_embed_builder.dart';
import 'package:test/test.dart';

void main() {
  group('MessageEmbedBuilder.setTimestamp (A11)', () {
    // A11 — Discord expects an absolute instant. Storing a bare local-zone
    // DateTime means the eventual `.toIso8601String()` (in the frozen
    // embed serializer) omits the Z suffix and, on a non-UTC host, encodes
    // the wrong instant.
    test('stores an explicit timestamp as UTC regardless of input zone', () {
      final utcInstant = DateTime.utc(2026, 8, 2, 12, 30, 0);
      final local = utcInstant.toLocal();

      final embed = MessageEmbedBuilder()
          .setTimestamp(timestamp: local)
          .build();

      expect(embed.timestamp!.isUtc, isTrue);
      expect(embed.timestamp, equals(utcInstant));
      expect(embed.timestamp!.toIso8601String(), endsWith('Z'));
    });

    test('defaults to DateTime.now() stored as UTC', () {
      final before = DateTime.now().toUtc();

      final embed = MessageEmbedBuilder().setTimestamp().build();

      final after = DateTime.now().toUtc();

      expect(embed.timestamp!.isUtc, isTrue);
      expect(embed.timestamp!.isBefore(before), isFalse);
      expect(embed.timestamp!.isAfter(after), isFalse);
    });
  });
}
