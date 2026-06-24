class HttpEndpoint {
  final String method;
  final String url;

  HttpEndpoint(this.method, this.url);

  factory HttpEndpoint.getServerChannelList({required String guildId}) =>
      HttpEndpoint('GET', '/guilds/$guildId/channels');

  factory HttpEndpoint.getServerChannel({
    required String guildId,
    required String channelId,
  }) => HttpEndpoint('GET', '/guilds/$guildId/channels/$channelId');

  @override
  String toString() => '[$method] $url';
}
