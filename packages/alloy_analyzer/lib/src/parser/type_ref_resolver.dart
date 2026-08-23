import 'package:alloy_analyzer/src/model/type_ref.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

AlloyTypeRef typeRefOfElement(InterfaceElement element) => AlloyTypeRef(
  name: element.displayName,
  import: element.library.uri.toString(),
);

AlloyTypeRef typeRefOf(DartType type) {
  final element = type.element;
  return AlloyTypeRef(
    name: element?.displayName ?? type.getDisplayString(),
    import: element?.library?.uri.toString(),
    typeArguments: [
      if (type is InterfaceType)
        for (final argument in type.typeArguments) typeRefOf(argument),
    ],
    isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
  );
}
