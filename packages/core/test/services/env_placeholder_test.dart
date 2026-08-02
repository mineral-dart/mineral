import 'dart:io';

import 'package:env_guard/env_guard.dart';
import 'package:mineral/src/infrastructure/internals/environment/app_env.dart';
import 'package:mineral/src/infrastructure/services/placeholder/env_placeholder.dart';
import 'package:test/test.dart';

const _fakeToken = 'FAKE.SECRET.VALUE';

enum _Mode implements Enumerable<String> {
  alpha('alpha'),
  beta('beta');

  @override
  final String value;

  const _Mode(this.value);
}

final class _FakeEnv implements DefineEnvironment {
  @override
  final Map<String, EnvSchema> schema = {
    'TOKEN': env.string(),
    'GUILD_ID': env.string(),
    'PREFIX': env.string(),
    'HOME': env.string(),
    'API_KEY': env.string(),
    'MODE': env.enumerable(_Mode.values),
  };
}

/// Writes a temporary `.env` file and points a temp directory at it, so
/// tests can seed the global env_guard singleton deterministically (with
/// `includeDartEnv: false`) without depending on, or polluting, the real
/// process environment.
Directory _writeEnvFile(String contents) {
  final tempDir = Directory.systemTemp.createTempSync('env_placeholder_test');
  File('${tempDir.path}/.env').writeAsStringSync(contents);
  return tempDir;
}

void main() {
  group('EnvPlaceholder', () {
    late Directory tempDir;

    setUp(() {
      tempDir = _writeEnvFile(
        'TOKEN=$_fakeToken\n'
        'GUILD_ID=123456789012345678\n'
        'PREFIX=!\n'
        'HOME=/should/not/leak\n'
        'API_KEY=super-secret-api-key\n'
        'MODE=alpha\n',
      );
      env.defineOf(_FakeEnv.new, root: tempDir, includeDartEnv: false);
    });

    tearDown(() {
      env.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('with no allowlist, exposes nothing (safe default)', () {
      final placeholder = EnvPlaceholder();
      expect(placeholder.values, isEmpty);
    });

    test('with an explicitly empty allowlist, exposes nothing', () {
      final placeholder = EnvPlaceholder(keys: {});
      expect(placeholder.values, isEmpty);
    });

    test('exposes only the allowlisted keys', () {
      final placeholder = EnvPlaceholder(keys: {'GUILD_ID', 'PREFIX'});
      expect(
        placeholder.values.keys,
        unorderedEquals(['env.GUILD_ID', 'env.PREFIX']),
      );
      expect(placeholder.values['env.GUILD_ID'], '123456789012345678');
      expect(placeholder.values['env.PREFIX'], '!');
    });

    test('never exposes TOKEN via values when TOKEN is not allowlisted', () {
      final placeholder = EnvPlaceholder(
        keys: {'GUILD_ID', 'PREFIX', 'HOME'},
      );
      expect(placeholder.values.containsKey('env.TOKEN'), isFalse);
      expect(placeholder.values.values, isNot(contains(_fakeToken)));
    });

    test(
      'hard-excludes TOKEN even when the caller explicitly allowlists it',
      () {
        final placeholder = EnvPlaceholder(keys: {'TOKEN', 'GUILD_ID'});
        expect(placeholder.values.containsKey('env.TOKEN'), isFalse);
        expect(placeholder.values.values, isNot(contains(_fakeToken)));
        expect(placeholder.values['env.GUILD_ID'], '123456789012345678');
      },
    );

    test(
      'hard-excludes TOKEN even when it is the only allowlisted key',
      () {
        final placeholder = EnvPlaceholder(keys: {'TOKEN'});
        expect(placeholder.values, isEmpty);
      },
    );

    test(
      'apply() never substitutes the token, even when TOKEN is allowlisted',
      () {
        final placeholder = EnvPlaceholder(keys: {'TOKEN'});
        final result = placeholder.apply(
          'leak={env.TOKEN} also={{ env.TOKEN }}',
        );
        expect(result, isNot(contains(_fakeToken)));
        expect(result, 'leak={env.TOKEN} also={{ env.TOKEN }}');
      },
    );

    test('apply() substitutes allowlisted values without throwing', () {
      final placeholder = EnvPlaceholder(keys: {'GUILD_ID', 'PREFIX'});
      final result = placeholder.apply(
        'guild={env.GUILD_ID} prefix={{ env.PREFIX }}',
      );
      expect(result, 'guild=123456789012345678 prefix=!');
    });

    test(
      'apply() stringifies enum-typed schema entries instead of throwing',
      () {
        final placeholder = EnvPlaceholder(keys: {'MODE'});
        expect(() => placeholder.apply('{env.MODE}'), returnsNormally);
        final result = placeholder.apply('{env.MODE}');
        expect(result, isNot('{env.MODE}'));
        expect(result, contains('alpha'));
      },
    );

    test(
      'redacts other secret-shaped keys even when explicitly allowlisted',
      () {
        final placeholder = EnvPlaceholder(keys: {'API_KEY'});
        expect(placeholder.values['env.API_KEY'], '***');
      },
    );
  });

  group('EnvPlaceholder against the real AppEnv schema (production shape)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = _writeEnvFile(
        'DART_ENV=development\n'
        'TOKEN=$_fakeToken\n'
        'DISCORD_REST_API_VERSION=10\n'
        'DISCORD_WS_VERSION=10\n'
        'INTENT=53608447\n'
        'LOG_LEVEL=INFO\n',
      );
      env.defineOf(AppEnv.new, root: tempDir, includeDartEnv: false);
    });

    tearDown(() {
      env.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'TOKEN cannot escape through values or apply() under the real schema, '
      'even when explicitly allowlisted',
      () {
        final placeholder = EnvPlaceholder(
          keys: {'TOKEN', 'DART_ENV', 'LOG_LEVEL'},
        );
        expect(placeholder.values.containsKey('env.TOKEN'), isFalse);
        expect(placeholder.values.values, isNot(contains(_fakeToken)));
        expect(placeholder.apply('{env.TOKEN}'), '{env.TOKEN}');
      },
    );

    test(
      'apply() does not throw on the enum-typed dartEnv/logLevel fields',
      () {
        final placeholder = EnvPlaceholder(keys: {'DART_ENV', 'LOG_LEVEL'});
        expect(
          () => placeholder.apply('{env.DART_ENV} / {env.LOG_LEVEL}'),
          returnsNormally,
        );
      },
    );

    test('EnvPlaceholder() with no allowlist exposes nothing at all', () {
      final placeholder = EnvPlaceholder();
      expect(placeholder.values, isEmpty);
    });
  });
}
