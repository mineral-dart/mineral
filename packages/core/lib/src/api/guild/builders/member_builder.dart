final class MemberBuilder {
  String? nickname;
  bool? isMuted;
  bool? isDeafened;
  bool? isExcluded;

  MemberBuilder({
    this.nickname,
    this.isMuted,
    this.isDeafened,
    this.isExcluded,
  });

  MemberBuilder setNickname(String value) {
    nickname = value;
    return this;
  }

  MemberBuilder mute(bool value) {
    isMuted = value;
    return this;
  }

  MemberBuilder deafen(bool value) {
    isDeafened = value;
    return this;
  }

  MemberBuilder exclude(bool value) {
    isExcluded = value;
    return this;
  }
}
