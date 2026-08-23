import 'package:alloy_analyzer/src/model/injected_property.dart';
import 'package:alloy_analyzer/src/model/type_ref.dart';
import 'package:alloy_annotations/alloy_annotations.dart';

class AlloyInjectableClass {
  const AlloyInjectableClass({
    required this.type,
    required this.lifetime,
    required this.constructorParameters,
    required this.properties,
    this.name,
    this.exposeAs,
    this.isAsyncInit = false,
    this.dependsOn = const [],
    this.environments = const {},
  });

  factory AlloyInjectableClass.fromJson(Map<String, dynamic> json) =>
      AlloyInjectableClass(
        type: AlloyTypeRef.fromJson(json['type'] as Map<String, dynamic>),
        lifetime: AlloyLifetime.values.byName(json['lifetime'] as String),
        constructorParameters: [
          for (final p in json['constructorParameters'] as List<dynamic>)
            AlloyInjectedProperty.fromJson(p as Map<String, dynamic>),
        ],
        properties: [
          for (final p in json['properties'] as List<dynamic>)
            AlloyInjectedProperty.fromJson(p as Map<String, dynamic>),
        ],
        name: json['name'] as String?,
        exposeAs: json['exposeAs'] == null
            ? null
            : AlloyTypeRef.fromJson(json['exposeAs'] as Map<String, dynamic>),
        isAsyncInit: json['isAsyncInit'] as bool? ?? false,
        dependsOn: [
          for (final d in json['dependsOn'] as List<dynamic>? ?? const [])
            AlloyTypeRef.fromJson(d as Map<String, dynamic>),
        ],
        environments: {
          for (final e in json['environments'] as List<dynamic>? ?? const [])
            e as String,
        },
      );

  final AlloyTypeRef type;
  final AlloyLifetime lifetime;
  final List<AlloyInjectedProperty> constructorParameters;
  final List<AlloyInjectedProperty> properties;
  final String? name;
  final AlloyTypeRef? exposeAs;
  final bool isAsyncInit;
  final List<AlloyTypeRef> dependsOn;

  /// Environment names this registration is restricted to, empty when it
  /// belongs to every graph.
  final Set<String> environments;

  AlloyTypeRef get exposedType => exposeAs ?? type;

  bool get hasPropertyInjection => properties.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'type': type.toJson(),
    'lifetime': lifetime.name,
    'constructorParameters': [
      for (final p in constructorParameters) p.toJson(),
    ],
    'properties': [for (final p in properties) p.toJson()],
    'name': name,
    'exposeAs': exposeAs?.toJson(),
    'isAsyncInit': isAsyncInit,
    'dependsOn': [for (final d in dependsOn) d.toJson()],
    'environments': [...environments],
  };
}
