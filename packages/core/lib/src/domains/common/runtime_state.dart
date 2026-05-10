import 'package:mineral/src/api/common/bot/bot.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/ready_packet.dart';

/// Mutable runtime state populated as the gateway lifecycle progresses.
///
/// Unlike the (mostly) immutable services in [AppState], these slots start
/// `null` and are filled at well-defined moments:
///
/// - [bot] is populated by [ReadyPacket] from the gateway's READY payload,
///   then read by [GuildCreatePacket] when commands are registered per
///   server, and by [Interaction] for the bot's own id.
/// - [readyPacketMessage] is populated by the packet dispatcher and read by
///   [HmrRunningStrategy] to replay the last READY across an HMR reload.
///
/// Replaces the previous `ioc.bind<Bot>` / `ioc.bind<ReadyPacketMessage>`
/// runtime registrations so the core never reads from the IoC.
final class RuntimeState {
  Bot? bot;
  ReadyPacketMessage? readyPacketMessage;
}
