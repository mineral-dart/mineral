/// Context passed to an autocomplete handler when Discord sends an
/// INTERACTION_CREATE event with type=4 (APPLICATION_COMMAND_AUTOCOMPLETE).
///
/// It exposes the focused option (name + partial value typed by the user)
/// and the other option values that the user has already filled in.
final class AutocompleteContext {
  /// The name of the focused option (the one triggering autocomplete).
  final String name;

  /// The partial string value that the user has typed so far.
  ///
  /// For integer/number options Discord still sends the partial input as a
  /// string, so this is always [String].
  final String value;

  /// All other options that the user has filled in, keyed by option name.
  ///
  /// The focused option itself is NOT included in this map.
  final Map<String, dynamic> options;

  const AutocompleteContext({
    required this.name,
    required this.value,
    required this.options,
  });
}
