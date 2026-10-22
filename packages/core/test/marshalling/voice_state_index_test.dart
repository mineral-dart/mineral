import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/voice_state_index.dart';
import 'package:test/test.dart';

import '../helpers/fake_cache_provider.dart';

void main() {
  late FakeCacheProvider cache;
  late CacheKey cacheKey;
  late VoiceStateIndex index;

  setUp(() {
    cache = FakeCacheProvider();
    cacheKey = CacheKey();
    index = VoiceStateIndex(cache: cache, cacheKey: cacheKey);
  });

  group('VoiceStateIndex', () {
    test('keysFor is empty for an unknown guild', () async {
      expect(await index.keysFor('1'), isEmpty);
    });

    test('add then keysFor returns full voice state keys', () async {
      await index.add('1', '10');
      await index.add('1', '11');

      expect(
        await index.keysFor('1'),
        equals([
          cacheKey.voiceState('1', '10'),
          cacheKey.voiceState('1', '11'),
        ]),
      );
    });

    test('add is idempotent', () async {
      await index.add('1', '10');
      await index.add('1', '10');

      expect(await index.keysFor('1'), hasLength(1));
    });

    test('remove drops only the given member', () async {
      await index.add('1', '10');
      await index.add('1', '11');
      await index.remove('1', '10');

      expect(
        await index.keysFor('1'),
        equals([cacheKey.voiceState('1', '11')]),
      );
    });

    test('guilds are isolated', () async {
      await index.add('1', '10');
      await index.add('2', '20');

      expect(
        await index.keysFor('1'),
        equals([cacheKey.voiceState('1', '10')]),
      );
    });

    test('concurrent adds for one guild keep every id', () async {
      await Future.wait([
        for (var i = 0; i < 50; i++) index.add('1', i.toString()),
      ]);

      expect(await index.keysFor('1'), hasLength(50));
    });

    test('concurrent add and remove stay consistent', () async {
      await index.add('1', 'a');
      await Future.wait([
        index.add('1', 'b'),
        index.remove('1', 'a'),
        index.add('1', 'c'),
      ]);

      expect(
        await index.keysFor('1'),
        unorderedEquals([
          cacheKey.voiceState('1', 'b'),
          cacheKey.voiceState('1', 'c'),
        ]),
      );
    });

    test('null cache is a no-op', () async {
      final noop = VoiceStateIndex(cache: null, cacheKey: cacheKey);

      await noop.add('1', '10');
      await noop.remove('1', '10');

      expect(await noop.keysFor('1'), isEmpty);
    });
  });
}
