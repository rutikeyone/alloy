class BootLog {
  BootLog._();

  static final entries = <String>[];

  static void record(String entry) => entries.add(entry);

  static void clear() => entries.clear();
}
