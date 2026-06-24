import 'dart:async';
import 'dart:collection';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/infrastructure/io/exceptions/service_not_found_exception.dart';

abstract interface class Disposable {
  FutureOr<void> dispose();
}

final class IocContainer {
  final IocContainer? _parent;
  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic> _defaults = {};
  final Map<Type, dynamic> _factories = {};
  final Set<Type> _requiredBindings = {};

  IocContainer([this._parent]);

  UnmodifiableMapView<Type, dynamic> get services =>
      UnmodifiableMapView(_services);

  IocContainer createScope() => IocContainer(this);

  void bind<T>(T Function() fn) {
    final service = fn();
    _services[T] = service;
    _defaults[T] = service;
  }

  /// Registers a factory that is invoked on every [resolve] call.
  ///
  /// Use this when the bound value is populated after [build] (e.g. `Bot`,
  /// which only exists once the gateway emits READY). The factory should
  /// throw a clear error if it is invoked before the value is available.
  void bindLazy<T>(T Function() factory) {
    _factories[T] = factory;
  }

  T make<T>(T Function() clazz) {
    final instance = clazz();
    _services[T] = instance;
    return instance;
  }

  T resolve<T>() {
    final service = _services[T];
    if (service is T) {
      return service;
    }

    final factory = _factories[T];
    if (factory is T Function()) {
      return factory();
    }

    if (_parent != null) {
      return _parent.resolve<T>();
    }
    throw ServiceNotFoundException(T);
  }

  T? resolveOrNull<T>() {
    final service = _services[T];
    if (service is T) {
      return service;
    }
    final factory = _factories[T];
    if (factory is T Function()) {
      return factory();
    }
    return _parent?.resolveOrNull<T>();
  }

  void override<T>(Constructable<T> clazz) {
    if (!_services.containsKey(T)) {
      throw ServiceNotFoundException(T);
    }

    _services[T] = clazz();
  }

  void restore<T>() {
    if (!_services.containsKey(T)) {
      throw ServiceNotFoundException(T);
    }

    _services[T] = _defaults[T];
  }

  void require<T>() {
    _requiredBindings.add(T);
  }

  void validateBindings() {
    final missing = _requiredBindings.where(
      (type) => !_services.containsKey(type) && !_factories.containsKey(type),
    );
    if (missing.isNotEmpty) {
      throw ServiceNotFoundException(missing.first);
    }
  }

  Future<void> dispose() async {
    for (final service in _services.values) {
      if (service case final Disposable disposable) {
        await disposable.dispose();
      }
    }
    _services.clear();
    _defaults.clear();
    _factories.clear();
    _requiredBindings.clear();
  }
}

IocContainer _ioc = IocContainer();

/// Returns the active [IocContainer].
///
/// Zone-based override takes precedence over the global container, which lets
/// tests inject a scoped container via [runWithIoc] without mutating shared
/// state.
IocContainer get ioc => Zone.current[#iocContainer] as IocContainer? ?? _ioc;

/// Swaps the global container for [container] and returns a restore function.
///
/// Prefer [runWithIoc] in new tests — it is Zone-scoped and safe for parallel
/// execution. [scopedIoc] is kept for backward compatibility.
IocContainer Function() scopedIoc(IocContainer container) {
  final previous = _ioc;
  _ioc = container;
  return () => _ioc = previous;
}

/// Runs [body] inside a Zone where [ioc] resolves to [container].
///
/// The Zone is automatically discarded when [body] completes, leaving the
/// global container untouched — no tearDown required.
///
/// ```dart
/// test('my test', () async {
///   final container = IocContainer()
///     ..bind<LoggerContract>(() => MockLogger());
///
///   await runWithIoc(container, () async {
///     // ioc.resolve<LoggerContract>() returns MockLogger here
///   });
/// });
/// ```
Future<T> runWithIoc<T>(IocContainer container, Future<T> Function() body) =>
    runZoned(body, zoneValues: {#iocContainer: container});
