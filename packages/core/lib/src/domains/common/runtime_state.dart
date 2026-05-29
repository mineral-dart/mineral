import 'package:mineral/src/api/common/bot/bot.dart';

/// Mutable runtime state populated as the gateway lifecycle progresses.
///
/// Unlike the (mostly) immutable services in [AppState], this slot starts
/// `null` and is filled by [ReadyPacket] from the gateway's READY payload.
/// It is then read by [GuildCreatePacket] when commands are registered per
/// server, and by [Interaction] for the bot's own id.
///
/// Replaces the previous `ioc.bind<Bot>` runtime registration so the core
/// never reads from the IoC.
final class RuntimeState {
  Bot? bot;
}
