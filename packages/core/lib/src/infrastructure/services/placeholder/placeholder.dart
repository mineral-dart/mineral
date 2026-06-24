import 'package:mineral/contracts.dart';

class Placeholder implements PlaceholderContract {
  final Map<String, dynamic> _values = {};

  @override
  final String? identifier;

  @override
  Map<String, dynamic> get values => _values;

  Placeholder({this.identifier, Map<String, dynamic>? values}) {
    if (values != null) {
      _injectEntryMap(identifier, values);
    }
  }

  Placeholder addEntry(String key, dynamic value) {
    _injectEntryMap(identifier, Map<String, dynamic>.from({key: value}));
    return this;
  }

  void _injectEntryMap(String? identifier, Map<String, dynamic> values) {
    final mapEntry = Map<String, dynamic>.from(
      values.map((key, value) {
        final hasIdentifier = key.contains('.');
        final finalKey = !hasIdentifier
            ? identifier != null
                  ? '$identifier.$key'
                  : key
            : key;

        return MapEntry(finalKey, value);
      }),
    );

    _values.addAll(mapEntry);
  }

  void merge(PlaceholderContract placeholder) {
    _injectEntryMap(placeholder.identifier, placeholder.values);
  }

  @override
  String apply(String value, {Map<String, dynamic>? values}) {
    String finalValue = value;
    if (values != null) {
      final currentValues = Map<String, dynamic>.from(
        values.map(
          (key, value) => identifier != null
              ? MapEntry('$identifier.$key', value)
              : MapEntry(key, value),
        ),
      );

      finalValue = _replace(value, currentValues);
    }

    return _replace(finalValue, this.values);
  }

  String _replace(String value, Map<String, dynamic> map) {
    return map.entries.fold(value, (acc, element) {
      final String finalValue = switch (element.value) {
        final String s => s,
        final int i => i.toString(),
        _ => throw Exception('Invalid type'),
      };

      return acc
          .replaceAllMapped(
            RegExp(r'\{\{\s*([^}]*)\s*\}\}'),
            (Match m) => '{{${m[1]?.trim()}}}',
          )
          .replaceAll('{{${element.key}}}', finalValue);
    });
  }
}
