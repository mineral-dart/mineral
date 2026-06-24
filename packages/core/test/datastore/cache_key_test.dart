import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';
import 'package:test/test.dart';

void main() {
  group('CacheKey', () {
    late CacheKey cacheKey;

    setUp(() {
      cacheKey = CacheKey();
    });

    group('guild', () {
      test('generates guild key', () {
        expect(cacheKey.guild('123'), 'guild/123');
      });

      test('works with numeric id', () {
        expect(cacheKey.guild(456), 'guild/456');
      });
    });

    group('guildAssets', () {
      test('generates guild assets key', () {
        expect(cacheKey.guildAssets('123'), 'guild/123/assets');
      });

      test('generates ref key when ref is true', () {
        expect(
            cacheKey.guildAssets('123', ref: true), 'ref:guild/123/assets');
      });

      test('generates non-ref key by default', () {
        expect(cacheKey.guildAssets('123').startsWith('ref:'), isFalse);
      });
    });

    group('guildSettings', () {
      test('generates guild settings key', () {
        expect(cacheKey.guildSettings('123'), 'guild/123/settings');
      });

      test('generates ref key when ref is true', () {
        expect(cacheKey.guildSettings('123', ref: true),
            'ref:guild/123/settings');
      });
    });

    group('guildRules', () {
      test('generates guild rules key', () {
        expect(cacheKey.guildRules('123', '456'), 'guild/123/rules/456');
      });

      test('generates ref key when ref is true', () {
        expect(cacheKey.guildRules('123', '456', ref: true),
            'ref:guild/123/rules/456');
      });
    });

    group('guildSubscription', () {
      test('generates guild subscription key', () {
        expect(cacheKey.guildSubscription('123'), 'guild/123/subscriptions');
      });

      test('generates ref key when ref is true', () {
        expect(cacheKey.guildSubscription('123', ref: true),
            'ref:guild/123/subscriptions');
      });
    });

    group('channel', () {
      test('generates channel key', () {
        expect(cacheKey.channel('789'), 'channels/789');
      });

      test('works with numeric id', () {
        expect(cacheKey.channel(789), 'channels/789');
      });
    });

    group('channelPermission', () {
      test('generates channel permission key', () {
        expect(cacheKey.channelPermission('789'), 'channels/789/permissions');
      });

      test('works with guildId parameter', () {
        expect(cacheKey.channelPermission('789', guildId: '123'),
            'channels/789/permissions');
      });
    });

    group('guildRole', () {
      test('generates guild role key', () {
        expect(cacheKey.guildRole('123', '456'), 'guild/123/roles/456');
      });
    });

    group('member', () {
      test('generates member key', () {
        expect(cacheKey.member('123', '456'), 'guild/123/members/456');
      });

      test('generates ref key when ref is true', () {
        expect(cacheKey.member('123', '456', ref: true),
            'ref:guild/123/members/456');
      });
    });

    group('memberAssets', () {
      test('generates member assets key', () {
        expect(cacheKey.memberAssets('123', '456'),
            'guild/123/members/456/assets');
      });

      test('generates ref key when ref is true', () {
        expect(cacheKey.memberAssets('123', '456', ref: true),
            'ref:guild/123/members/456/assets');
      });
    });

    group('user', () {
      test('generates user key', () {
        expect(cacheKey.user('789'), 'users/789');
      });

      test('generates ref key when ref is true', () {
        expect(cacheKey.user('789', ref: true), 'ref:users/789');
      });
    });

    group('voiceState', () {
      test('generates voice state key', () {
        expect(cacheKey.voiceState('123', '456'),
            'voice_states/guild/123/members/456');
      });
    });

    group('invite', () {
      test('generates invite key', () {
        expect(cacheKey.invite('abc123'), 'invites/abc123');
      });
    });

    group('userAssets', () {
      test('generates user assets key', () {
        expect(cacheKey.userAssets('789'), 'users/789/assets');
      });

      test('generates ref key when ref is true', () {
        expect(cacheKey.userAssets('789', ref: true), 'ref:users/789/assets');
      });
    });

    group('guildEmoji', () {
      test('generates guild emoji key', () {
        expect(cacheKey.guildEmoji('123', '456'), 'guild/123/emojis/456');
      });
    });

    group('message', () {
      test('generates message key', () {
        expect(cacheKey.message('789', '101'), 'channels/789/messages/101');
      });
    });

    group('embed', () {
      test('generates embed key with fixed uid', () {
        expect(
            cacheKey.embed('101', uid: 'fixed'), 'messages/101/embeds/fixed');
      });

      test('generates embed key with auto-generated uuid', () {
        final key = cacheKey.embed('101');
        expect(key, startsWith('messages/101/embeds/'));
        expect(key.length, greaterThan('messages/101/embeds/'.length));
      });

      test('generates unique keys without uid', () {
        final key1 = cacheKey.embed('101');
        final key2 = cacheKey.embed('101');
        expect(key1, isNot(equals(key2)));
      });
    });

    group('poll', () {
      test('generates poll key with fixed uid', () {
        expect(cacheKey.poll('101', uid: 'fixed'), 'messages/101/polls/fixed');
      });

      test('generates poll key with auto-generated uuid', () {
        final key = cacheKey.poll('101');
        expect(key, startsWith('messages/101/polls/'));
        expect(key.length, greaterThan('messages/101/polls/'.length));
      });

      test('generates unique keys without uid', () {
        final key1 = cacheKey.poll('101');
        final key2 = cacheKey.poll('101');
        expect(key1, isNot(equals(key2)));
      });
    });

    group('sticker', () {
      test('generates sticker key', () {
        expect(cacheKey.sticker('123', '456'), 'guild/123/stickers/456');
      });
    });

    group('thread', () {
      test('generates thread key', () {
        expect(cacheKey.thread('789'), 'threads/789');
      });
    });

    group('ref pattern consistency', () {
      test('all ref keys start with ref:', () {
        final refKeys = [
          cacheKey.guildAssets('1', ref: true),
          cacheKey.guildSettings('1', ref: true),
          cacheKey.guildRules('1', '2', ref: true),
          cacheKey.guildSubscription('1', ref: true),
          cacheKey.member('1', '2', ref: true),
          cacheKey.memberAssets('1', '2', ref: true),
          cacheKey.user('1', ref: true),
          cacheKey.userAssets('1', ref: true),
        ];

        for (final key in refKeys) {
          expect(key, startsWith('ref:'),
              reason: '$key should start with ref:');
        }
      });

      test('non-ref keys do not start with ref:', () {
        final nonRefKeys = [
          cacheKey.guildAssets('1'),
          cacheKey.guildSettings('1'),
          cacheKey.guildRules('1', '2'),
          cacheKey.guildSubscription('1'),
          cacheKey.member('1', '2'),
          cacheKey.memberAssets('1', '2'),
          cacheKey.user('1'),
          cacheKey.userAssets('1'),
        ];

        for (final key in nonRefKeys) {
          expect(key.startsWith('ref:'), isFalse,
              reason: '$key should not start with ref:');
        }
      });
    });

    group('hierarchical nesting', () {
      test('member key contains guild key', () {
        final memberKey = cacheKey.member('123', '456');
        expect(memberKey, contains(cacheKey.guild('123')));
      });

      test('memberAssets key contains member key', () {
        final assetsKey = cacheKey.memberAssets('123', '456');
        expect(assetsKey, contains(cacheKey.member('123', '456')));
      });

      test('message key contains channel key', () {
        final messageKey = cacheKey.message('789', '101');
        expect(messageKey, contains(cacheKey.channel('789')));
      });

      test('guildRole key contains guild key', () {
        final roleKey = cacheKey.guildRole('123', '456');
        expect(roleKey, contains(cacheKey.guild('123')));
      });

      test('guildEmoji key contains guild key', () {
        final emojiKey = cacheKey.guildEmoji('123', '456');
        expect(emojiKey, contains(cacheKey.guild('123')));
      });

      test('sticker key contains guild key', () {
        final stickerKey = cacheKey.sticker('123', '456');
        expect(stickerKey, contains(cacheKey.guild('123')));
      });

      test('userAssets key contains user key', () {
        final assetsKey = cacheKey.userAssets('789');
        expect(assetsKey, contains(cacheKey.user('789')));
      });
    });
  });
}
