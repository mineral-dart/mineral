import 'package:mineral/api.dart';

abstract class InteractionContract {
  DateTime get createdAt;

  /// Use to reply to the interaction.
  /// Usage:
  ///
  /// ```dart
  /// final interaction = await interaction.reply(content: 'Hello Mineral');
  /// ```
  Future<InteractionContract> reply({
    required MessageBuilder builder,
    bool ephemeral = false,
  });

  /// Use to edit the reply to the interaction.
  /// Usage:
  ///
  /// ```dart
  /// final interaction = await interaction.editReply(content: 'New Hello Mineral');
  Future<InteractionContract> editReply({
    required MessageBuilder builder,
    bool ephemeral = false,
  });

  /// Use to delete the reply to the interaction. Need a reply to delete.
  /// Usage:
  ///
  /// ```dart
  /// await interaction.deleteReply();
  /// ```
  Future<void> deleteReply();

  /// Use to not reply to the interaction, prevent the 'This interaction failed' message.
  /// Usage:
  ///
  /// ```dart
  /// await interaction.noReply();
  /// ```
  Future<void> noReply({bool ephemeral = false});

  /// Use to follow up the interaction.
  /// Usage:
  ///
  /// ```dart
  /// final interaction = await interaction.followUp(content: 'Hello Mineral');
  /// ```
  Future<InteractionContract> followup({
    required MessageBuilder builder,
    bool ephemeral = false,
  });

  /// Use to edit the follow up message.
  /// Usage:
  ///
  /// ```dart
  /// final interaction = await interaction.editFollowUp(content: 'New Hello Mineral');
  /// ```
  Future<InteractionContract> editFollowup({
    required MessageBuilder builder,
    bool ephemeral = false,
  });

  /// Use to delete the follow up message.
  /// Usage:
  ///
  /// ```dart
  /// await interaction.deleteFollowUp();
  /// ```
  Future<void> deleteFollowup();

  /// Use to defer the interaction, like a loading state.
  /// Usage:
  ///
  /// ```dart
  /// await interaction.defer();
  /// ```
  Future<InteractionContract> wait();

  // TODO: Edit the documentation
  /// Use to send a modal to the interaction.
  ///
  /// Usage:
  /// ```dart
  /// final modal = ModalBuilder('unique_custom_id')
  ///   ..setTitle('Hello')
  ///   ..text('hello', (input) => input
  ///     ..setLabel('Hello')
  ///     ..setPlaceholder('World');
  ///   );
  ///
  /// await interaction.modal(modal);
  /// ```
  Future<void> modal(ModalBuilder modal);
}
