import 'package:mineral/src/domains/services/cache/cache_ttl_policy.dart';
import 'package:test/test.dart';

void main() {
  group('CacheTtlPolicy.defaults', () {
    final policy = CacheTtlPolicy.defaults();

    test('users are cached for 1 hour', () {
      expect(policy.ttlFor('users/789'), const Duration(hours: 1));
    });

    test('guilds are cached for 4 hours', () {
      expect(policy.ttlFor('guild/123'), const Duration(hours: 4));
    });

    test('members override the parent guild rule (30 min)', () {
      expect(
        policy.ttlFor('guild/123/members/456'),
        const Duration(minutes: 30),
      );
    });

    test('roles are cached for 4 hours via segment match', () {
      expect(policy.ttlFor('guild/123/roles/456'), const Duration(hours: 4));
    });

    test('emojis are cached for 12 hours', () {
      expect(policy.ttlFor('guild/123/emojis/456'), const Duration(hours: 12));
    });

    test('stickers are cached for 12 hours', () {
      expect(
        policy.ttlFor('guild/123/stickers/456'),
        const Duration(hours: 12),
      );
    });

    test('messages override channels (10 min)', () {
      expect(
        policy.ttlFor('channels/789/messages/101'),
        const Duration(minutes: 10),
      );
    });

    test('channels are cached for 2 hours', () {
      expect(policy.ttlFor('channels/789'), const Duration(hours: 2));
    });

    test('embeds inherit messages/ prefix (10 min)', () {
      expect(
        policy.ttlFor('messages/101/embeds/abc'),
        const Duration(minutes: 10),
      );
    });

    test('threads are cached for 2 hours', () {
      expect(policy.ttlFor('threads/789'), const Duration(hours: 2));
    });

    test('voice states are cached for 5 minutes', () {
      expect(
        policy.ttlFor('voice_states/guild/123/members/456'),
        const Duration(minutes: 5),
      );
    });

    test('invites are cached for 1 hour', () {
      expect(policy.ttlFor('invites/abc123'), const Duration(hours: 1));
    });

    test('ref pointers never expire', () {
      expect(policy.ttlFor('ref:users/789'), isNull);
    });

    test('webhooks are cached for 1 hour', () {
      expect(policy.ttlFor('webhooks/123456789'), const Duration(hours: 1));
    });

    test(
      'unlisted key families fall through to the conservative 1-hour default',
      () {
        expect(policy.ttlFor('foo/bar'), const Duration(hours: 1));
        expect(
          policy.ttlFor('arbitrary/unlisted/key'),
          const Duration(hours: 1),
        );
      },
    );
  });

  group('CacheTtlPolicy.disabled', () {
    final policy = CacheTtlPolicy.disabled();

    test('returns null for any key', () {
      expect(policy.ttlFor('users/789'), isNull);
      expect(policy.ttlFor('guild/123/members/456'), isNull);
      expect(policy.ttlFor('whatever'), isNull);
    });
  });

  group('CacheTtlPolicy.override', () {
    test('prefix override takes priority over defaults', () {
      final policy = CacheTtlPolicy.defaults().override({
        'users/': const Duration(seconds: 30),
      });

      expect(policy.ttlFor('users/789'), const Duration(seconds: 30));
      expect(policy.ttlFor('guild/123'), const Duration(hours: 4));
    });

    test('segment override (leading slash) wins over base segment rules', () {
      final policy = CacheTtlPolicy.defaults().override({
        '/members/': const Duration(seconds: 5),
      });

      expect(
        policy.ttlFor('guild/123/members/456'),
        const Duration(seconds: 5),
      );
    });

    test('override with null disables expiration for that key family', () {
      final policy = CacheTtlPolicy.defaults().override({'users/': null});

      expect(policy.ttlFor('users/789'), isNull);
    });

    test('override does not mutate the original policy', () {
      final base = CacheTtlPolicy.defaults();
      final derived = base.override({'users/': const Duration(seconds: 1)});

      expect(base.ttlFor('users/789'), const Duration(hours: 1));
      expect(derived.ttlFor('users/789'), const Duration(seconds: 1));
    });

    test('multiple overrides are applied in declaration order', () {
      final policy = CacheTtlPolicy.disabled().override({
        'a/': const Duration(seconds: 1),
        'a/b/': const Duration(seconds: 2),
      });

      // Both rules match 'a/b/c' but the first declared wins.
      expect(policy.ttlFor('a/b/c'), const Duration(seconds: 1));
    });
  });
}
