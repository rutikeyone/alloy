import 'package:cobalt/cobalt.dart';
import 'package:cobalt_external_consumer/src/clock.dart';
import 'package:cobalt_external_consumer/src/search_index.dart';

part 'report.g.dart';

@cobaltTransient
class Report with _$Report {
  Report();

  @injected
  late final Clock _clock;

  @injected
  late final SearchIndex _index;

  String render() =>
      'report ${_clock.now().toIso8601String()} indexed=${_index.isBuilt}';
}
