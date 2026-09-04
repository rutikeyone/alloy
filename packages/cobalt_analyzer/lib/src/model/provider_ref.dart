import 'package:cobalt_analyzer/src/model/type_ref.dart';

/// The module member that builds a registration.
///
/// Present only on a declaration that came from an `@CobaltModule` class; a
/// declaration parsed from `@CobaltInject` on a class has none, and is built by
/// calling its constructor instead.
class CobaltProviderRef {
  const CobaltProviderRef({
    required this.module,
    required this.member,
    required this.isGetter,
  });

  factory CobaltProviderRef.fromJson(Map<String, dynamic> json) =>
      CobaltProviderRef(
        module: CobaltTypeRef.fromJson(json['module'] as Map<String, dynamic>),
        member: json['member'] as String,
        isGetter: json['isGetter'] as bool? ?? false,
      );

  /// The class carrying the member.
  final CobaltTypeRef module;

  /// The member's name.
  final String member;

  /// Whether it is read as a property rather than called.
  final bool isGetter;

  Map<String, dynamic> toJson() => {
    'module': module.toJson(),
    'member': member,
    'isGetter': isGetter,
  };
}
