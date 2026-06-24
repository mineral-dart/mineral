final class MemberTimeout {
  DateTime? duration;
  bool get isTimeout => duration != null;

  MemberTimeout({required this.duration});
}
