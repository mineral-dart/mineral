enum CommandContextType {
  guild(0),
  global(1);

  final int value;
  const CommandContextType(this.value);
}
