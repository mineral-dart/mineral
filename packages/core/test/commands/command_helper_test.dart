import 'package:mineral/src/api/common/commands/builder/translation.dart';
import 'package:mineral/src/api/common/commands/command_helper.dart';
import 'package:mineral/src/api/common/lang.dart';
import 'package:mineral/src/infrastructure/io/exceptions/command_name_exception.dart';
import 'package:test/test.dart';

void main() {
  group('CommandHelper', () {
    final helper = CommandHelper();

    group('verifyName', () {
      test('accepts simple alphanumeric names', () {
        expect(() => helper.verifyName('ping'), returnsNormally);
        expect(() => helper.verifyName('ban'), returnsNormally);
        expect(() => helper.verifyName('hello123'), returnsNormally);
      });

      test('accepts names with hyphens and underscores', () {
        expect(() => helper.verifyName('my-command'), returnsNormally);
        expect(() => helper.verifyName('my_command'), returnsNormally);
        expect(() => helper.verifyName('a-b_c'), returnsNormally);
      });

      test('accepts names with apostrophes', () {
        expect(() => helper.verifyName("it's"), returnsNormally);
      });

      test('accepts single character names', () {
        expect(() => helper.verifyName('a'), returnsNormally);
        expect(() => helper.verifyName('1'), returnsNormally);
      });

      test('accepts names up to 32 characters', () {
        final name = 'a' * 32;
        expect(() => helper.verifyName(name), returnsNormally);
      });

      test('accepts unicode Hindi characters', () {
        expect(
          () => helper.verifyName('\u0915\u092E\u093E\u0902\u0921'),
          returnsNormally,
        );
      });

      test('accepts unicode Thai characters', () {
        expect(
          () => helper.verifyName('\u0E04\u0E33\u0E2A\u0E31\u0E48\u0E07'),
          returnsNormally,
        );
      });

      test('rejects names with spaces', () {
        expect(
          () => helper.verifyName('my command'),
          throwsA(isA<CommandNameException>()),
        );
      });

      test('rejects empty names', () {
        expect(
          () => helper.verifyName(''),
          throwsA(isA<CommandNameException>()),
        );
      });

      test('rejects names longer than 32 characters', () {
        final name = 'a' * 33;
        expect(
          () => helper.verifyName(name),
          throwsA(isA<CommandNameException>()),
        );
      });

      test('rejects names with special characters', () {
        expect(
          () => helper.verifyName('hello!'),
          throwsA(isA<CommandNameException>()),
        );
        expect(
          () => helper.verifyName('cmd@name'),
          throwsA(isA<CommandNameException>()),
        );
        expect(
          () => helper.verifyName('test#1'),
          throwsA(isA<CommandNameException>()),
        );
        expect(
          () => helper.verifyName('a+b'),
          throwsA(isA<CommandNameException>()),
        );
      });

      test('rejects names with dots', () {
        expect(
          () => helper.verifyName('cmd.name'),
          throwsA(isA<CommandNameException>()),
        );
      });
    });

    group('extractTranslations', () {
      test('extracts translations for matching key', () {
        final translation = Translation({
          'name': {Lang.fr: 'commande', Lang.enUS: 'command'},
        });

        final result = helper.extractTranslations('name', translation);

        expect(result, isNotNull);
        expect(result!['fr'], 'commande');
        expect(result['en-US'], 'command');
      });

      test('returns null for non-matching key', () {
        final translation = Translation({
          'name': {Lang.fr: 'commande'},
        });

        final result = helper.extractTranslations('description', translation);
        expect(result, isNull);
      });

      test('handles multiple languages', () {
        final translation = Translation({
          'description': {
            Lang.fr: 'desc fr',
            Lang.de: 'desc de',
            Lang.ja: 'desc ja',
            Lang.ko: 'desc ko',
          },
        });

        final result = helper.extractTranslations('description', translation);

        expect(result, isNotNull);
        expect(result!.length, 4);
        expect(result['fr'], 'desc fr');
        expect(result['de'], 'desc de');
        expect(result['ja'], 'desc ja');
        expect(result['ko'], 'desc ko');
      });

      test('handles empty translations map', () {
        final translation = Translation({});
        final result = helper.extractTranslations('name', translation);
        expect(result, isNull);
      });
    });
  });
}
