import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/fake_entity_context.dart';
import '../helpers/fake_marshaller.dart';
import '../helpers/mocks.dart';

final class _UserPart implements UserPartContract {
  final List<String> calls = [];

  @override
  Future<User?> get(Object id, bool force) async {
    calls.add(id.toString());
    return User(
      ctx: fakeEntityContext(),
      id: Snowflake.parse(id.toString()),
      username: 'TestUser',
      discriminator: '0001',
      avatar: null,
      bot: false,
      system: false,
      mfaEnabled: false,
      locale: 'en-US',
      verified: true,
      email: null,
      flags: 0,
      premiumType: PremiumTier.none,
      publicFlags: 0,
      assets: UserAssets(avatar: null, avatarDecoration: null, banner: null),
      createdAt: DateTime.now(),
      presence: null,
    );
  }
}

Map<String, dynamic> _payload(Map<String, dynamic> invoker) => {
  'id': '111111111111111111',
  'application_id': '222222222222222222',
  'token': 'fake-token',
  'version': 1,
  'channel_id': '333333333333333333',
  ...invoker,
};

void main() {
  late _UserPart userPart;
  late MockDataStore ds;

  setUp(() {
    userPart = _UserPart();
    ds = MockDataStore();
    final channelPart = MockChannelPart();
    when(
      () => channelPart.get<Channel>(any(), any()),
    ).thenAnswer((_) async => null);
    when(() => ds.channel).thenReturn(channelPart);
    when(() => ds.user).thenReturn(userPart);
  });

  Future<GlobalCommandContext> build(Map<String, dynamic> payload) =>
      GlobalCommandContext.fromMap(
        FakeMarshaller(),
        ds,
        fakeEntityContext(),
        payload,
      );

  test('DM payload with top-level user and no member builds', () async {
    final context = await build(
      _payload({
        'user': {'id': '444444444444444444'},
      }),
    );

    expect(context.user.id.value, '444444444444444444');
    expect(userPart.calls, ['444444444444444444']);
  });

  test('payload with member only still builds', () async {
    final context = await build(
      _payload({
        'member': {
          'user': {'id': '555555555555555555'},
        },
      }),
    );

    expect(context.user.id.value, '555555555555555555');
  });

  test('payload without user nor member throws StateError', () async {
    expect(() => build(_payload({})), throwsStateError);
  });
}
