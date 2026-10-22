import 'package:mineral/api.dart';

final class RedisEnv implements DefineEnvironment {
  static final String redisHost = 'REDIS_HOST';
  static final String redisPort = 'REDIS_PORT';
  static final String redisPassword = 'REDIS_PASSWORD';
  static final String redisTls = 'REDIS_TLS';

  @override
  final Map<String, EnvSchema> schema = {
    redisHost: env.string(),
    redisPort: env.number(),
    redisPassword: env.string(),
    redisTls: env.boolean().optional(),
  };
}
