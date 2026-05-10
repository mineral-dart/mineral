import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/providers/provider.dart';

abstract interface class ProviderManagerContract {
  void register(ProviderContract provider);
  Future<void> ready();
  Future<void> dispose();
}

final class ProviderManager implements ProviderManagerContract {
  final List<ProviderContract> _providers = [];

  final LoggerContract _logger;

  ProviderManager({required LoggerContract logger}) : _logger = logger;

  @override
  void register(ProviderContract provider) {
    _providers.add(provider);
  }

  @override
  Future<void> ready() async {
    for (final provider in _providers) {
      try {
        await provider.ready();
      } on Exception catch (e) {
        _logger
            .error('Provider ${provider.runtimeType} failed to initialize: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> dispose() async {
    for (final provider in _providers.reversed) {
      try {
        await provider.dispose();
      } on Exception catch (e) {
        _logger.error('Provider ${provider.runtimeType} failed to dispose: $e');
      }
    }
  }
}
