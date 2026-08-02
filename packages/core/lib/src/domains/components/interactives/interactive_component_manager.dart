import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';

abstract interface class InteractiveComponentService {
  T get<T extends InteractiveComponent>(String customId);
}

abstract interface class InteractiveComponentManagerContract
    implements InteractiveComponentService {
  void Function(
    InteractiveComponent component,
    Object error,
    StackTrace stackTrace,
  )?
  onComponentError;

  void register(InteractiveComponent component);

  Future<void> dispatch(String customId, List params);
}

final class InteractiveComponentManager
    implements InteractiveComponentManagerContract {
  final Map<String, InteractiveComponent> _components = {};

  @override
  void Function(
    InteractiveComponent component,
    Object error,
    StackTrace stackTrace,
  )?
  onComponentError;

  final LoggerContract _logger;

  InteractiveComponentManager({required LoggerContract logger})
    : _logger = logger;

  @override
  void register(InteractiveComponent component) {
    _components[component.customId] = component;
  }

  @override
  Future<void> dispatch(String customId, List params) async {
    final component = _components[customId];
    if (component == null) {
      return;
    }

    try {
      switch (component) {
        case final InteractiveButton button when params.isNotEmpty:
          await button.handle(params[0] as ButtonContext);
        case final InteractiveModal modal when params.length >= 2:
          await modal.handle(params[0] as ModalContext, params[1]);
        case final InteractiveSelectMenu select when params.length >= 2:
          await select.handle(params[0] as SelectContext, params[1]);
        default:
          return;
      }
    } on Exception catch (e, stackTrace) {
      _logger
        ..error('Failed to dispatch component "$customId": $e')
        ..trace('$stackTrace');
      onComponentError?.call(component, e, stackTrace);
      // ignore: avoid_catching_errors, crash-safety boundary for component handlers
    } on Error catch (e, stackTrace) {
      _logger
        ..error('Failed to dispatch component "$customId": $e')
        ..trace('$stackTrace');
      onComponentError?.call(component, e, stackTrace);
    }
  }

  @override
  T get<T extends InteractiveComponent>(String customId) =>
      _components.values.firstWhere(
            (e) => e.customId == customId,
            orElse: () => throw InvalidComponentException(
              'Component "$customId" not found',
            ),
          )
          as T;
}
