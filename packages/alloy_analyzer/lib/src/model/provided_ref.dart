import 'package:alloy_analyzer/src/model/type_ref.dart';

class AlloyProvidedRef {
  const AlloyProvidedRef({required this.type, this.name});

  factory AlloyProvidedRef.fromJson(Map<String, dynamic> json) =>
      AlloyProvidedRef(
        type: AlloyTypeRef.fromJson(json['type'] as Map<String, dynamic>),
        name: json['name'] as String?,
      );

  final AlloyTypeRef type;
  final String? name;

  Map<String, dynamic> toJson() => {'type': type.toJson(), 'name': name};
}
