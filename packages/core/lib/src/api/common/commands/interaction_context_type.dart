enum InteractionContextType {
  guild(0),
  botDm(1),
  privateChannel(2);

  final int value;
  const InteractionContextType(this.value);
}
