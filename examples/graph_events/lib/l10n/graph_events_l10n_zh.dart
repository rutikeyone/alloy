// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'graph_events_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class GraphEventsL10nZh extends GraphEventsL10n {
  GraphEventsL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Cobalt · 可观测性';

  @override
  String get liveLog => '实时日志';

  @override
  String get everyEvent => '下面每一条事件都是依赖图在报告自己';

  @override
  String get everyEventDetail =>
      'CobaltTalkerObserver 把每一类事件归到各自的标题下，因此日志界面可以把它们分开筛选。';

  @override
  String get openSession => '打开一个会话作用域';

  @override
  String get openSessionDetail => '一次入栈、一次异步初始化、若干实例';

  @override
  String get openBrokenSession => '打开一个关不掉的';

  @override
  String get openBrokenSessionDetail => '它的释放会抛出异常，这是故意的';

  @override
  String get closeSession => '关闭会话';

  @override
  String get nothingOpen => '没有打开任何东西';

  @override
  String scopeNamed(String name) {
    return '作用域 “$name”';
  }

  @override
  String get eventsRecorded => '已记录的事件';

  @override
  String get noFailures => '尚未报告任何失败';

  @override
  String get noFailuresDetail => '去关闭那个关不掉的会话';

  @override
  String reportSummary(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条痕迹',
    );
    return '$kind · $_temp0';
  }
}
