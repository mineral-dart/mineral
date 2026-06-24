import 'dart:async';

import 'package:mineral/container.dart';
import 'package:mineral/src/infrastructure/io/exceptions/service_not_found_exception.dart';
import 'package:test/test.dart';

abstract interface class AbstractClass {}

final class FooWithoutAbstract {}

final class Foo implements AbstractClass {}

final class Bar implements AbstractClass {}

final class DisposableService implements Disposable {
  bool disposed = false;

  @override
  FutureOr<void> dispose() {
    disposed = true;
  }
}

void main() {
  group('service ioc', () {
    final ioc = IocContainer();

    tearDown(ioc.dispose);

    test('can bind service with concrete type', () {
      ioc.bind(Foo.new);
      expect(ioc.resolve<Foo>(), isA<Foo>());
    });

    test('can bind service with concrete type in generic', () {
      ioc.bind<Foo>(Foo.new);
      expect(ioc.resolve<Foo>(), isA<Foo>());
    });

    test('can bind service with abstract type', () {
      ioc.bind<AbstractClass>(Foo.new);
      expect(ioc.resolve<AbstractClass>(), isA<Foo>());
    });

    test('can override service', () {
      ioc.bind<AbstractClass>(Foo.new);
      expect(ioc.resolve<AbstractClass>(), isA<Foo>());

      ioc.override<AbstractClass>(Bar.new);
      expect(ioc.resolve<AbstractClass>(), isA<Bar>());
    });

    test('cannot override a non-existent service', () {
      expect(() => ioc.override<AbstractClass>(Bar.new), throwsException);
    });

    test('can override service then restore it', () {
      ioc
        ..bind<AbstractClass>(Foo.new)
        ..override<AbstractClass>(Bar.new)
        ..restore<AbstractClass>();

      expect(ioc.resolve<AbstractClass>(), isA<Foo>());
    });
  });

  group('resolve type safety', () {
    final ioc = IocContainer();

    tearDown(ioc.dispose);

    test('resolve throws on missing service', () {
      expect(() => ioc.resolve<Foo>(), throwsException);
    });

    test('resolveOrNull returns null on missing service', () {
      expect(ioc.resolveOrNull<Foo>(), isNull);
    });
  });

  group('make type safety', () {
    final ioc = IocContainer();

    tearDown(ioc.dispose);

    test('make returns typed instance', () {
      final result = ioc.make<AbstractClass>(Foo.new);
      expect(result, isA<Foo>());
    });
  });

  group('validateBindings', () {
    final ioc = IocContainer();

    tearDown(ioc.dispose);

    test('passes when all required services are registered', () {
      ioc
        ..require<AbstractClass>()
        ..require<Foo>()
        ..bind<AbstractClass>(Foo.new)
        ..bind<Foo>(Foo.new);

      expect(ioc.validateBindings, returnsNormally);
    });

    test('throws with missing services listed', () {
      ioc
        ..require<AbstractClass>()
        ..require<Foo>()
        ..bind<Foo>(Foo.new);

      expect(
        ioc.validateBindings,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('AbstractClass'),
        )),
      );
    });

    test('passes with no requirements', () {
      ioc.bind<Foo>(Foo.new);
      expect(ioc.validateBindings, returnsNormally);
    });
  });

  group('scoped containers', () {
    final parent = IocContainer();

    tearDown(parent.dispose);

    test('child resolves services from parent', () {
      parent.bind<AbstractClass>(Foo.new);
      final child = parent.createScope();

      expect(child.resolve<AbstractClass>(), isA<Foo>());
    });

    test('child can override parent service without polluting parent', () {
      parent.bind<AbstractClass>(Foo.new);
      final child = parent.createScope()..bind<AbstractClass>(Bar.new);

      expect(child.resolve<AbstractClass>(), isA<Bar>());
      expect(parent.resolve<AbstractClass>(), isA<Foo>());
    });

    test('child resolveOrNull falls back to parent', () {
      parent.bind<Foo>(Foo.new);
      final child = parent.createScope();

      expect(child.resolveOrNull<Foo>(), isA<Foo>());
    });

    test('child resolveOrNull returns null when neither has service', () {
      final child = parent.createScope();
      expect(child.resolveOrNull<Foo>(), isNull);
    });
  });

  group('scopedIoc', () {
    test('replaces and restores global container', () {
      final scope = IocContainer()..bind<Foo>(Foo.new);

      final restore = scopedIoc(scope);
      expect(ioc.resolve<Foo>(), isA<Foo>());

      restore();
      expect(ioc.resolveOrNull<Foo>(), isNull);

      scope.dispose();
    });
  });

  group('dispose with Disposable', () {
    test('calls dispose on services implementing Disposable', () async {
      final container = IocContainer()
        ..bind<DisposableService>(DisposableService.new);

      final service = container.resolve<DisposableService>();
      expect(service.disposed, isFalse);

      await container.dispose();
      expect(service.disposed, isTrue);
    });

    test('does not throw when disposing non-Disposable services', () async {
      final container = IocContainer()..bind<Foo>(Foo.new);

      await expectLater(container.dispose(), completes);
    });

    test('calls dispose on all Disposable services', () async {
      final container = IocContainer()
        ..bind<DisposableService>(DisposableService.new)
        ..bind<Foo>(Foo.new);

      final service = container.resolve<DisposableService>();

      await container.dispose();
      expect(service.disposed, isTrue);
    });
  });

  group('ServiceNotFoundException', () {
    final container = IocContainer();

    tearDown(container.dispose);

    test('resolve throws ServiceNotFoundException on missing service', () {
      expect(
        () => container.resolve<Foo>(),
        throwsA(isA<ServiceNotFoundException>()),
      );
    });

    test('override throws ServiceNotFoundException on missing service', () {
      expect(
        () => container.override<Foo>(Foo.new),
        throwsA(isA<ServiceNotFoundException>()),
      );
    });

    test('restore throws ServiceNotFoundException on missing service', () {
      expect(
        () => container.restore<Foo>(),
        throwsA(isA<ServiceNotFoundException>()),
      );
    });

    test('exception contains the service type', () {
      expect(
        () => container.resolve<Foo>(),
        throwsA(isA<ServiceNotFoundException>()
            .having((e) => e.serviceType, 'serviceType', Foo)),
      );
    });
  });

  group('multiple scopes', () {
    test('grandchild resolves service from grandparent', () {
      final grandparent = IocContainer()..bind<AbstractClass>(Foo.new);
      final parent = grandparent.createScope();
      final grandchild = parent.createScope();

      expect(grandchild.resolve<AbstractClass>(), isA<Foo>());

      grandparent.dispose();
    });

    test('grandchild resolveOrNull falls back to grandparent', () {
      final grandparent = IocContainer()..bind<Foo>(Foo.new);
      final parent = grandparent.createScope();
      final grandchild = parent.createScope();

      expect(grandchild.resolveOrNull<Foo>(), isA<Foo>());

      grandparent.dispose();
    });

    test('middle scope override does not affect grandparent', () {
      final grandparent = IocContainer()..bind<AbstractClass>(Foo.new);
      final parent = grandparent.createScope()..bind<AbstractClass>(Bar.new);
      final grandchild = parent.createScope();

      expect(grandchild.resolve<AbstractClass>(), isA<Bar>());
      expect(grandparent.resolve<AbstractClass>(), isA<Foo>());

      grandparent.dispose();
    });

    test('grandchild override does not affect parent or grandparent', () {
      final grandparent = IocContainer()..bind<AbstractClass>(Foo.new);
      final parent = grandparent.createScope();
      final grandchild = parent.createScope()..bind<AbstractClass>(Bar.new);

      expect(grandchild.resolve<AbstractClass>(), isA<Bar>());
      expect(parent.resolve<AbstractClass>(), isA<Foo>());
      expect(grandparent.resolve<AbstractClass>(), isA<Foo>());

      grandparent.dispose();
    });

    test('grandchild returns null when no scope has the service', () {
      final grandparent = IocContainer();
      final parent = grandparent.createScope();
      final grandchild = parent.createScope();

      expect(grandchild.resolveOrNull<Foo>(), isNull);

      grandparent.dispose();
    });
  });
}
