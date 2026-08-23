class BootLog {
  BootLog._();

  static final steps = <String>[];

  static void record(String step) => steps.add(step);

  static void reset() => steps.clear();
}
