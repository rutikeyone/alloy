import 'package:alloy/alloy.dart';

@AlloyInit()
class Database implements AsyncInitializable {
  Database();

  var isOpen = false;

  @override
  Future<void> init() async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    isOpen = true;
  }
}
