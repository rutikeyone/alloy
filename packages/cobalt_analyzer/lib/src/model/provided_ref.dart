import 'package:cobalt_analyzer/src/model/type_ref.dart';

class CobaltProvidedRef {
  const CobaltProvidedRef({required this.type, this.name});

  factory CobaltProvidedRef.fromJson(Map<String, dynamic> json) =>
      CobaltProvidedRef(
        type: CobaltTypeRef.fromJson(json['type'] as Map<String, dynamic>),
        name: json['name'] as String?,
      );

  final CobaltTypeRef type;
  final String? name;

  Map<String, dynamic> toJson() => {'type': type.toJson(), 'name': name};
}
