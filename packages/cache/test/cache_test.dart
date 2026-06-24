import './memory_test.dart' as memory_test;
import './memory_ttl_test.dart' as memory_ttl_test;
import './redis_commands_test.dart' as redis_commands_test;
import './redis_provider_logic_test.dart' as redis_provider_logic_test;

void main() {
  memory_test.main();
  memory_ttl_test.main();
  redis_commands_test.main();
  redis_provider_logic_test.main();
}
