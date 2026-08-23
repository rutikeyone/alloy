import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/src/clock.dart';
import 'package:alloy_external_consumer/src/search_index.dart';

part 'report.g.dart';

@alloyTransient
class Report with _$Report {
  Report();

  @injected
  late final Clock _clock;

  @injected
  late final SearchIndex _index;

  String render() =>
      'report ${_clock.now().toIso8601String()} indexed=${_index.isBuilt}';
}
