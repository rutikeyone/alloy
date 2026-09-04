// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'codegen_basics_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class CodegenBasicsL10nZh extends CodegenBasicsL10n {
  CodegenBasicsL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Alloy 代码生成基础';

  @override
  String environment(String name) {
    return '运行环境：$name';
  }

  @override
  String greeting(String name, String environment) {
    return '你好，$name，来自 $environment';
  }

  @override
  String get increment => '增加';
}
