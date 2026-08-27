import 'package:alloy_analyzer/src/model/type_ref.dart';

class AlloyInjectedProperty {
  const AlloyInjectedProperty({
    required this.field,
    required this.type,
    this.name,
    this.isNamed = false,
    this.isParam = false,
  });

  factory AlloyInjectedProperty.fromJson(Map<String, dynamic> json) =>
      AlloyInjectedProperty(
        field: json['field'] as String,
        type: AlloyTypeRef.fromJson(json['type'] as Map<String, dynamic>),
        name: json['name'] as String?,
        isNamed: json['isNamed'] as bool? ?? false,
        isParam: json['isParam'] as bool? ?? false,
      );

  final String field;
  final AlloyTypeRef type;
  final String? name;

  /// Whether the constructor takes this as a named parameter.
  ///
  /// The call has to be rebuilt the way it was declared: passing a named
  /// parameter positionally produces a generated file that does not compile.
  final bool isNamed;

  /// Whether the value comes from the call site rather than from the graph.
  ///
  /// Marked with `@AlloyParam`. Such a parameter is not a dependency: nothing
  /// registers it, it is no edge in the ordering, and it arrives through
  /// `getWithParam` instead.
  final bool isParam;

  Map<String, dynamic> toJson() => {
    'field': field,
    'type': type.toJson(),
    'name': name,
    if (isNamed) 'isNamed': true,
    if (isParam) 'isParam': true,
  };
}
