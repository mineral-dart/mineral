import 'package:mineral/src/api/common/commands/builder/translation.dart';
import 'package:mineral/src/api/common/lang.dart';
import 'package:mineral/src/infrastructure/io/exceptions/command_name_exception.dart';

final class CommandHelper {
  // Note: allows Devanagari (\u0900-\u097F) and Thai (\u0E00-\u0E7F) per Discord spec.
  // Full Unicode homoglyph protection (NFC/NFD normalisation) requires an external
  // package and is not enforced here — Discord validates names guild-side.
  final _regex = RegExp(
    r"^[-_'a-z0-9\u0900-\u097F\u0E00-\u0E7F]{1,32}$",
    unicode: true,
  );

  Map<String, String>? extractTranslations(
      String key, Translation translations) {
    if (translations.translations[key] case final Map<Lang, String> elements) {
      return elements.entries.fold({}, (acc, element) {
        return {...?acc, element.key.uid: element.value};
      });
    }

    return null;
  }

  void verifyName(String name) {
    if (!_regex.hasMatch(name.toLowerCase())) {
      throw CommandNameException('Invalid command name for $name.');
    }
  }
}
