import 'package:alloy_analyzer/src/model/type_ref.dart';

class AlloyScopeRootClass {
  const AlloyScopeRootClass({required this.type, required this.name});

  factory AlloyScopeRootClass.fromJson(Map<String, dynamic> json) =>
      AlloyScopeRootClass(
        type: AlloyTypeRef.fromJson(json['type'] as Map<String, dynamic>),
        name: json['name'] as String,
      );

  final AlloyTypeRef type;
  final String name;

  Map<String, dynamic> toJson() => {'type': type.toJson(), 'name': name};
}
