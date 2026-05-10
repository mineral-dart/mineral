import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/server/member.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class MemberManager {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake _serverId;

  MemberManager(this._serverId, {required EntityContext ctx}) : _ctx = ctx;

  /// Fetch the server's channels.
  /// ```dart
  /// final members = await server.members.fetch();
  /// print(members.humans);
  /// print(members.bots);
  /// ```
  Future<MemberRecord> fetch({bool force = false}) async {
    final members = await _datastore.member.fetch(_serverId.value, force);
    return MemberRecord(members);
  }

  /// Get a channel by its id.
  /// ```dart
  /// final members = await server.members.get('1091121140090535956');
  /// ```
  Future<Member?> get(String id, {bool force = false}) =>
      _datastore.member.get(_serverId.value, id, force);
}

final class MemberRecord {
  final Map<Snowflake, Member> members;
  MemberRecord(this.members);

  Map<Snowflake, Member> get humans {
    return members.entries.where((element) => !element.value.isBot).fold({},
        (value, element) {
      return {...value, element.key: element.value};
    });
  }

  Map<Snowflake, Member> get bots {
    return members.entries.where((element) => element.value.isBot).fold({},
        (value, element) {
      return {...value, element.key: element.value};
    });
  }
}
