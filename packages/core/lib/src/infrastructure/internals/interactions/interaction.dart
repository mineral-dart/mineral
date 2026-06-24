import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';

final class Interaction implements InteractionContract {
  final String _token;
  final Snowflake _id;

  final DataStoreContract _datastore;
  final RuntimeState _runtimeState;

  Snowflake get _botId =>
      _runtimeState.bot?.id ??
      (throw StateError(
        'Interaction created before bot identity was set by READY.',
      ));

  Interaction(
    this._token,
    this._id, {
    required DataStoreContract datastore,
    required RuntimeState runtimeState,
  }) : _datastore = datastore,
       _runtimeState = runtimeState;

  @override
  DateTime get createdAt => _id.createdAt;

  @override
  Future<InteractionContract> reply({
    required MessageBuilder builder,
    bool ephemeral = false,
  }) async {
    await _datastore.interaction.replyInteraction(
      _id,
      _token,
      builder,
      ephemeral,
    );

    return this;
  }

  @override
  Future<InteractionContract> editReply({
    required MessageBuilder builder,
    bool ephemeral = false,
  }) async {
    await _datastore.interaction.editInteraction(
      _botId,
      _token,
      builder,
      ephemeral,
    );
    return this;
  }

  @override
  Future<void> deleteReply() async {
    await _datastore.interaction.deleteInteraction(_botId, _token);
  }

  @override
  Future<void> noReply({bool ephemeral = false}) async {
    await _datastore.interaction.noReplyInteraction(_id, _token, ephemeral);
  }

  @override
  Future<InteractionContract> followup({
    required MessageBuilder builder,
    bool ephemeral = false,
  }) async {
    await _datastore.interaction.createFollowup(
      _botId,
      _token,
      builder,
      ephemeral,
    );
    return this;
  }

  @override
  Future<InteractionContract> editFollowup({
    required MessageBuilder builder,
    bool ephemeral = false,
  }) async {
    await _datastore.interaction.editFollowup(
      _botId,
      _token,
      _id,
      builder,
      ephemeral,
    );
    return this;
  }

  @override
  Future<void> deleteFollowup() async {
    await _datastore.interaction.deleteFollowup(_botId, _token, _id);
  }

  @override
  Future<InteractionContract> wait() async {
    await _datastore.interaction.waitInteraction(_id, _token);
    return this;
  }

  @override
  Future<void> modal(ModalBuilder modal) async {
    await _datastore.interaction.sendModal(_id, _token, modal);
  }
}
