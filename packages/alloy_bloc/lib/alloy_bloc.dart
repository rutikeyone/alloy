/// Lets an Alloy scope close the blocs it built.
///
/// Pure Dart on `bloc` rather than `flutter_bloc`, the same split
/// [`alloy_talker`](https://pub.dev/packages/alloy_talker) makes: nothing here
/// needs widgets, and a bloc registered in a scope is a bloc whether or not
/// Flutter is present.
library;

export 'package:alloy_bloc/src/alloy_bloc_mixin.dart';
export 'package:alloy_bloc/src/close_bloc.dart';
