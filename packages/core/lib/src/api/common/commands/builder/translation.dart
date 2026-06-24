import 'dart:convert';
import 'dart:io';

import 'package:mineral/src/api/common/lang.dart';
import 'package:mineral/src/infrastructure/io/exceptions/invalid_command_exception.dart';
import 'package:yaml/yaml.dart';

final class Translation {
  final Map<String, Map<Lang, String>> translations;

  Translation(this.translations);

  // factory Translation.json(Map<String, String> values) => Translation(values);

  /// Load translation from [File].
  ///
  /// Support json, yaml and toml
  factory Translation.file({required File file, required String key}) {
    final Map<String, Map<Lang, String>> entries = {};
    final stringContent = file.readAsStringSync();

    final Map<String, dynamic> content = switch (file) {
      File(:final uri) when uri.path.endsWith('.json') =>
        jsonDecode(stringContent) as Map<String, dynamic>,
      // File(:final uri) when uri.path.endsWith('.toml') => TomlDocument.parse(stringContent),
      File(:final uri) when uri.path.endsWith('.yaml') =>
        (loadYaml(stringContent) as YamlMap).toMap(),
      File(:final uri) when uri.path.endsWith('.yml') =>
        (loadYaml(stringContent) as YamlMap).toMap(),
      _ => throw InvalidCommandException('File type not supported'),
    };

    final Map<String, dynamic> translations =
        (content['commands'] as Map<String, dynamic>)[key]
            as Map<String, dynamic>;

    for (final translation in translations.entries) {
      final Map<Lang, String> map = {};

      for (final MapEntry element
          in (translation.value as Map<dynamic, dynamic>).entries) {
        final lang = Lang.values.firstWhere(
          (lang) => lang.uid == element.key,
          orElse: () => throw InvalidCommandException(
            'Lang "${element.key}" does not exist in the available languages',
          ),
        );

        map.putIfAbsent(lang, () => element.value as String);
      }

      entries.putIfAbsent(translation.key, () => map);
    }

    return Translation(entries);
  }
}

extension YamlMapConverter on YamlMap {
  dynamic _convertNode(dynamic v) {
    if (v is YamlMap) {
      return v.toMap();
    } else if (v is YamlList) {
      final list = <dynamic>[];
      for (final e in v) {
        list.add(_convertNode(e));
      }
      return list;
    } else {
      return v;
    }
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    nodes.forEach((k, v) {
      map[(k as YamlScalar).value.toString()] = _convertNode(v.value);
    });
    return map;
  }
}
