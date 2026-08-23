import 'package:alloy_analyzer/src/model/type_ref.dart';

class AlloyBootstrapStepClass {
  const AlloyBootstrapStepClass({
    required this.type,
    required this.order,
    this.environments = const {},
  });

  factory AlloyBootstrapStepClass.fromJson(Map<String, dynamic> json) =>
      AlloyBootstrapStepClass(
        type: AlloyTypeRef.fromJson(json['type'] as Map<String, dynamic>),
        order: json['order'] as int,
        environments: {
          for (final e in json['environments'] as List<dynamic>? ?? const [])
            e as String,
        },
      );

  final AlloyTypeRef type;
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
