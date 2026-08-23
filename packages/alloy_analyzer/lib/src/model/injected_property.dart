import 'package:alloy_analyzer/src/model/type_ref.dart';

class AlloyInjectedProperty {
  const AlloyInjectedProperty({
    required this.field,
    required this.type,
    this.name,
  });

  factory AlloyInjectedProperty.fromJson(Map<String, dynamic> json) =>
      AlloyInjectedProperty(
        field: json['field'] as String,
        type: AlloyTypeRef.fromJson(json['type'] as Map<String, dynamic>),
        name: json['name'] as String?,
      );

  final String field;
  final AlloyTypeRef type;
  final String? name;

  Map<String, dynamic> toJson() => {
    'field': field,
    'type': type.toJson(),
    'name': name,
  };
}
