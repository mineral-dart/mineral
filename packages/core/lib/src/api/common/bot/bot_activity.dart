import 'package:mineral/api.dart';

class BotActivity {
  String? name;
  GamePresence type;
  String? url;
  PartialEmoji? emoji;
  String? state;

  BotActivity({
    required this.type,
    this.name,
    this.url,
    this.emoji,
    this.state,
  });

  Object toJson() {
    return {
      'name': name,
      'type': type.value,
      if (url != null) 'url': url,
      if (state != null) 'state': state,
    };
  }

  factory BotActivity.playing(String name) {
    return BotActivity(name: name, type: GamePresence.game);
  }

  factory BotActivity.watching(String name) {
    return BotActivity(name: name, type: GamePresence.watching);
  }

  factory BotActivity.listening(String name) {
    return BotActivity(name: name, type: GamePresence.listening);
  }

  factory BotActivity.streaming(String name, String url) {
    return BotActivity(name: name, type: GamePresence.streaming, url: url);
  }
}
