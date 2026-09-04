import 'package:cobalt_analyzer/src/model/type_ref.dart';

class CobaltBootstrapStepClass {
  const CobaltBootstrapStepClass({
    required this.type,
    required this.order,
    this.environments = const {},
  });

  factory CobaltBootstrapStepClass.fromJson(Map<String, dynamic> json) =>
      CobaltBootstrapStepClass(
        type: CobaltTypeRef.fromJson(json['type'] as Map<String, dynamic>),
        order: json['order'] as int,
        environments: {
          for (final e in json['environments'] as List<dynamic>? ?? const [])
            e as String,
        },
      );

  final CobaltTypeRef type;
  final int order;

  /// Environment names this step is restricted to, empty when it runs in
  /// every graph.
  final Set<String> environments;

  Map<String, dynamic> toJson() => {
    'type': type.toJson(),
    'order': order,
    'environments': [...environments],
  };
}
