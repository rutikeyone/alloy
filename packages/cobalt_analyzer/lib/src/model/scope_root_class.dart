import 'package:cobalt_analyzer/src/model/provided_ref.dart';
import 'package:cobalt_analyzer/src/model/type_ref.dart';

class CobaltScopeRootClass {
  const CobaltScopeRootClass({
    required this.type,
    required this.name,
    this.provides = const [],
  });

  factory CobaltScopeRootClass.fromJson(Map<String, dynamic> json) =>
      CobaltScopeRootClass(
        type: CobaltTypeRef.fromJson(json['type'] as Map<String, dynamic>),
        name: json['name'] as String,
        provides: [
          for (final p in json['provides'] as List<dynamic>? ?? const [])
            CobaltProvidedRef.fromJson(p as Map<String, dynamic>),
        ],
      );

  final CobaltTypeRef type;
  final String name;

  /// Registrations the package makes by hand, which the generator must treat
  /// as present even though it cannot see them.
  final List<CobaltProvidedRef> provides;

  Map<String, dynamic> toJson() => {
    'type': type.toJson(),
    'name': name,
    'provides': [for (final p in provides) p.toJson()],
  };
}
