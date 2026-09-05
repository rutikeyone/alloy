import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// The names a teardown can go by.
///
/// `cancel` is here for what a class *holds* rather than what it is: a
/// subscription and a timer are cancelled, a controller and a notifier are
/// closed or disposed.
const _teardownNames = ['dispose', 'close', 'cancel'];

/// The name of [element]'s teardown method, or null when it offers none.
///
/// Teardown-shaped means it can be called with nothing and answers nothing
/// worth keeping: no required parameters, returning `void` or a `Future`. A
/// `close()` that takes a reason and returns a result is some other method
/// that happens to share a name.
///
/// Shared by the two rules that ask this question — one about a registration
/// the scope cannot release, one about a resource it holds. They have to agree
/// on the shape, or a class lands in both reports or in neither.
String? teardownMethodOf(InterfaceElement element) {
  for (final name in _teardownNames) {
    final method =
        element.methods.where((it) => it.name == name).firstOrNull ??
        element.allSupertypes
            .expand((supertype) => supertype.methods)
            .where((it) => it.name == name)
            .firstOrNull;
    if (method == null) continue;
    if (method.formalParameters.any((it) => it.isRequired)) continue;
    if (!_isTeardownReturn(method.returnType)) continue;
    return name;
  }
  return null;
}

bool _isTeardownReturn(DartType type) =>
    type is VoidType || type.isDartAsyncFuture || type.isDartAsyncFutureOr;
