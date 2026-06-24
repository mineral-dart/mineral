import 'package:mineral/api.dart';

abstract interface class VoteCounterContract
    implements GlobalState<Map<String, int>> {
  void voteYes();
  void voteNo();
}

final class VoteCounter implements VoteCounterContract {
  int _yes = 0;
  int _no = 0;

  @override
  Map<String, int> get state => {'yes': _yes, 'no': _no};

  @override
  void voteYes() => _yes++;

  @override
  void voteNo() => _no++;
}
