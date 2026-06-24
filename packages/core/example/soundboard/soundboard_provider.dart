import 'package:mineral/api.dart';

import 'sounds_command.dart';

final class SoundboardProvider extends Provider {
  final Client _client;

  SoundboardProvider(this._client) {
    _client.register<SoundsCommand>(SoundsCommand.new);
  }
}
