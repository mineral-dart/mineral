import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/container/ioc_container.dart';
import 'package:mineral/src/domains/global_states/global_state_manager.dart';
import 'package:mineral/src/domains/services/logger/logger_contract.dart'
    as logger_service;

export 'package:mineral/src/domains/container/ioc_container.dart'
    show Disposable, IocContainer, ioc, runWithIoc, scopedIoc;
export 'package:mineral/src/domains/global_states/global_state_manager.dart'
    show GlobalStateService;

mixin Logger {
  logger_service.LoggerContract get logger =>
      ioc.resolve<logger_service.LoggerContract>();
}

mixin State {
  GlobalStateService get state => ioc.resolve<GlobalStateManager>();
}

mixin Components {
  InteractiveComponentService get components =>
      ioc.resolve<InteractiveComponentManagerContract>();
}
