// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'codegen_basics_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CodegenBasicsL10nEn extends CodegenBasicsL10n {
  CodegenBasicsL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Alloy codegen basics';

  @override
  String environment(String name) {
    return 'environment: $name';
  }

  @override
  String greeting(String name, String environment) {
    return 'hello $name from $environment';
  }

  @override
  String get increment => 'increment';
}
