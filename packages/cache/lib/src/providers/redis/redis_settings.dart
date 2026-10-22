final class RedisSettings {
  final String host;
  final int port;
  final bool hasPassword;
  final bool tls;

  RedisSettings(
    this.host,
    this.port, {
    this.hasPassword = false,
    this.tls = false,
  });
}
