import 'package:code_builder/code_builder.dart';

class HashedAllocator implements Allocator {
  static const _doNotPrefix = ['dart:core'];

  final _imports = <String, int>{};
  final _usedAliases = <int>{};

  String? _url;

  @override
  String allocate(Reference reference) {
    final symbol = reference.symbol;
    _url = reference.url;
    if (_url == null || _doNotPrefix.contains(_url)) {
      return symbol!;
    }
    return '_i${_imports.putIfAbsent(_url!, _hashedUrl)}.$symbol';
  }

  int _hashedUrl() {
    var alias = _url.hashCode / 1000000 ~/ 1;
    while (!_usedAliases.add(alias)) {
      alias++;
    }
    return alias;
  }

  @override
  Iterable<Directive> get imports =>
      _imports.keys.map((u) => Directive.import(u, as: '_i${_imports[u]}'));
}
