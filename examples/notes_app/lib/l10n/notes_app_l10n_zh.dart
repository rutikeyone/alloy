// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'notes_app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class NotesL10nZh extends NotesL10n {
  NotesL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get twoPhaseStartup => '两阶段启动';

  @override
  String get restartGraph => '释放应用作用域并重新启动一个';

  @override
  String get phaseZero => '阶段 0 —— @CobaltBootstrap';

  @override
  String phaseZeroNote(String scope) {
    return '由作用域 “$scope” 收养，随它一起释放';
  }

  @override
  String get phaseOne => '阶段 1 —— @CobaltInit';

  @override
  String get databaseOpen => '数据库已打开';

  @override
  String get searchIndexBuilt => '搜索索引已构建';

  @override
  String get telemetryStarted => '遥测已启动';

  @override
  String statusLine(String label, String value) {
    return '$label：$value';
  }

  @override
  String apiLine(String url) {
    return 'api：$url';
  }

  @override
  String get sessionScope => '会话作用域';

  @override
  String signedInAs(String name) {
    return '已登录：$name';
  }

  @override
  String get signedOut => '未登录';

  @override
  String scopeLine(String name) {
    return '作用域：$name';
  }

  @override
  String get noScope => '无';

  @override
  String get signIn => '登录';

  @override
  String get signOut => '退出登录';

  @override
  String get recordActivity => '记录一次活动';

  @override
  String activityCount(int count) {
    return '活动：$count';
  }

  @override
  String get sessionExplained =>
      '退出登录会释放会话作用域。在它内部构建的一切都随之消失 —— 任何仓储都不需要 reset()，也不需要任何一处监听会话。';

  @override
  String get propertyInjection => '属性注入';

  @override
  String get search => '搜索';

  @override
  String noteCount(int count) {
    return '数量：$count';
  }

  @override
  String newNote(int number) {
    return '笔记 $number';
  }

  @override
  String get widgetOwnedScope => '由控件持有的作用域';

  @override
  String get draft => '草稿';

  @override
  String get untitled => '未命名';

  @override
  String get widgetScopeExplained => '这个界面声明了自己的作用域。离开它就会释放该作用域 —— 别处再不用记着这件事。';

  @override
  String get scopeTree => '作用域树';

  @override
  String get namedAndMulti => '命名注入与多重注入';

  @override
  String registrationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个注册',
    );
    return '$_temp0';
  }

  @override
  String get sampleNote => '购物清单';

  @override
  String get environments => '运行环境';

  @override
  String get activeEnvironment => '当前环境';

  @override
  String apiClientLine(String implementation, String detail) {
    return '$implementation → $detail';
  }

  @override
  String get noNetwork => '无网络';

  @override
  String nothingRegistered(String environment) {
    return '没有任何注册 —— 没有实现声明属于 “$environment”';
  }

  @override
  String get crashReportingStep => 'report-crashes 启动步骤';

  @override
  String get stepRan => '已执行';

  @override
  String get stepSkipped => '在此环境下被跳过';

  @override
  String get environmentsExplained =>
      '两个实现都标注了同一个 exposeAs。只有声明了当前环境的那一个会被注册，因此下游谁也不知道自己拿到的是哪一个。选一个没人声明的环境，这个类型就干脆不存在 —— get<ApiClient>() 会抛异常，而不是把错误的类交给你。';
}
