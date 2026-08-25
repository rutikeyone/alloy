import 'package:alloy_analyzer/src/model/provided_ref.dart';
import 'package:alloy_analyzer/src/model/type_ref.dart';

class AlloyScopeRootClass {
  const AlloyScopeRootClass({
    required this.type,
    required this.name,
    this.provides = const [],
  });

  factory AlloyScopeRootClass.fromJson(Map<String, dynamic> json) =>
      AlloyScopeRootClass(
        type: AlloyTypeRef.fromJson(json['type'] as Map<String, dynamic>),
        name: json['name'] as String,
        provides: [
          for (final p in json['provides'] as List<dynamic>? ?? const [])
            AlloyProvidedRef.fromJson(p as Map<String, dynamic>),
        ],
      );

  final AlloyTypeRef type;
  final String name;

  /// Registrations the package makes by hand, which the generator must treat
  /// as present even though it cannot see them.
  final List<AlloyProvidedRef> provides;

  Map<String, dynamic> toJson() => {
    'type': type.toJson(),
    'name': name,
    'provides': [for (final p in provides) p.toJson()],
  };
}
