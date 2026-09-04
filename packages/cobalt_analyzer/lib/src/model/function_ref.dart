/// A reference to a function the generated code calls by name.
///
/// [owner] is set when the function is a static member, and null when it is
/// top level.
class CobaltFunctionRef {
  const CobaltFunctionRef({required this.name, this.import, this.owner});

  factory CobaltFunctionRef.fromJson(Map<String, dynamic> json) =>
      CobaltFunctionRef(
        name: json['name'] as String,
        import: json['import'] as String?,
        owner: json['owner'] as String?,
      );

  final String name;
  final String? import;
  final String? owner;

  Map<String, dynamic> toJson() => {
    'name': name,
    'import': import,
    'owner': owner,
  };
}
