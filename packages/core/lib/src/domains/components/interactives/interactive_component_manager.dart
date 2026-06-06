import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';

abstract interface class InteractiveComponentService {
  T get<T extends InteractiveComponent>(String customId);
}

abstract interface class InteractiveComponentManagerContract
    implements InteractiveComponentService {
  void register(InteractiveComponent component);

  void dispatch(String customId, List params);
}

final class InteractiveComponentManager
    implements InteractiveComponentManagerContract {
  final Map<String, InteractiveComponent> _components = {};

  @override
  void register(InteractiveComponent component) {
    _components[component.customId] = component;
  }

  @override
  void dispatch(String customId, List params) {
    final component = _components[customId];
    if (component == null) {
      return;
    }

    switch (component) {
      case final InteractiveButton button when params.isNotEmpty:
        button.handle(params[0] as ButtonContext);
      case final InteractiveModal modal when params.length >= 2:
        modal.handle(params[0] as ModalContext, params[1]);
      case final InteractiveSelectMenu select when params.length >= 2:
        select.handle(params[0] as SelectContext, params[1]);
      default:
        return;
    }
  }

  @override
  T get<T extends InteractiveComponent>(String customId) =>
      _components.values.firstWhere((e) => e.customId == customId,
          orElse: () => throw InvalidComponentException(
              'Component "$customId" not found')) as T;
}
