/// Root of the Mineral exception hierarchy.
///
/// Sealed so that every catch site can exhaustively switch on
/// [RecoverableMineralException] vs [FatalMineralException].
sealed class MineralException implements Exception {
  final String message;

  MineralException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// An exception the bot can catch, log, and potentially recover from.
///
/// Examples: invalid command definition, serialisation failure for a single
/// event, unknown service binding.
abstract class RecoverableMineralException extends MineralException {
  RecoverableMineralException(super.message);
}

/// An exception that indicates the bot cannot continue running.
///
/// Examples: invalid bot token, Discord gateway permanently closed the
/// connection.
abstract class FatalMineralException extends MineralException {
  FatalMineralException(super.message);
}
