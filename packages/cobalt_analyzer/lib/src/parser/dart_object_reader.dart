import 'package:analyzer/dart/constant/value.dart';

extension CobaltDartObject on DartObject {
  String? readString(String field) => getField(field)?.toStringValue();

  int? readInt(String field) => getField(field)?.toIntValue();

  int? readEnumIndex(String field) =>
      getField(field)?.getField('index')?.toIntValue();
}
