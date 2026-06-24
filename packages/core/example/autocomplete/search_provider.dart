import 'package:mineral/api.dart';

import 'search_command.dart';

final class SearchProvider extends Provider {
  final Client _client;

  SearchProvider(this._client) {
    _client.register<SearchCommand>(SearchCommand.new);
  }
}
