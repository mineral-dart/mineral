import 'package:mineral/src/domains/services/cache/cache_provider_contract.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/cache_key.dart';

final class VoiceStateIndex {
  final CacheProviderContract? _cache;
  final CacheKey _cacheKey;
  final Map<String, Future<void>> _chains = {};

  VoiceStateIndex({
    required CacheProviderContract? cache,
    required CacheKey cacheKey,
  }) : _cache = cache,
       _cacheKey = cacheKey;

  Future<void> add(String guildId, String userId) {
    return _enqueue(guildId, () async {
      final members = await _read(guildId);
      if (members.contains(userId)) {
        return;
      }

      await _cache!.put<Map<String, dynamic>>(
        _cacheKey.voiceStateIndex(guildId),
        {
          'members': [...members, userId],
        },
      );
    });
  }

  Future<void> remove(String guildId, String userId) {
    return _enqueue(guildId, () async {
      final members = await _read(guildId);
      if (!members.contains(userId)) {
        return;
      }

      await _cache!.put<Map<String, dynamic>>(
        _cacheKey.voiceStateIndex(guildId),
        {'members': members.where((id) => id != userId).toList()},
      );
    });
  }

  Future<List<String>> keysFor(String guildId) async {
    if (_cache == null) {
      return const [];
    }

    final members = await _read(guildId);
    return members.map((id) => _cacheKey.voiceState(guildId, id)).toList();
  }

  Future<List<String>> _read(String guildId) async {
    final raw = await _cache!.get(_cacheKey.voiceStateIndex(guildId));
    final members = raw?['members'] as List?;
    return members?.map((id) => id.toString()).toList() ?? [];
  }

  Future<void> _enqueue(String guildId, Future<void> Function() mutation) {
    if (_cache == null) {
      return Future.value();
    }

    final next = (_chains[guildId] ?? Future.value()).then((_) => mutation());
    final tail = next.then<void>((_) {}, onError: (_) {});
    _chains[guildId] = tail;
    tail.then((_) {
      if (identical(_chains[guildId], tail)) {
        _chains.remove(guildId);
      }
    });

    return next;
  }
}
