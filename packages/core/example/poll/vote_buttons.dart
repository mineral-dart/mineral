import 'package:mineral/api.dart';
import 'package:mineral/container.dart';
import 'package:mineral/events.dart';

import '../global_states/vote_counter.dart';

final class VoteYesButton extends GuildButtonClickEvent with State {
  @override
  String? get customId => 'poll_vote:yes';

  @override
  Future<void> handle(GuildButtonContext ctx) async {
    state.read<VoteCounterContract>().voteYes();

    await ctx.interaction.wait();
    final message = await ctx.resolveMessage();
    await ctx.interaction.editReply(
      builder: MessageBuilder.text('${message.content}\n\n✅ Someone voted **Yes**!'),
    );
  }
}

final class VoteNoButton extends GuildButtonClickEvent with State {
  @override
  String? get customId => 'poll_vote:no';

  @override
  Future<void> handle(GuildButtonContext ctx) async {
    state.read<VoteCounterContract>().voteNo();

    await ctx.interaction.wait();
    final message = await ctx.resolveMessage();
    await ctx.interaction.editReply(
      builder: MessageBuilder.text('${message.content}\n\n❌ Someone voted **No**!'),
    );
  }
}

final class PollResultsButton extends GuildButtonClickEvent with State {
  @override
  String? get customId => 'poll_results';

  @override
  Future<void> handle(GuildButtonContext ctx) async {
    final counts = state.read<VoteCounterContract>().state;
    final yes = counts['yes'] ?? 0;
    final no = counts['no'] ?? 0;

    await ctx.interaction.reply(
      builder: MessageBuilder.text('📊 Results — Yes: **$yes** / No: **$no**'),
      ephemeral: true,
    );
  }
}
