import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/app/gallery_app.dart';

void main() {
  // Debug only: with asserts off this never runs and the service extension
  // does not exist, which is what a release build wants.
  assert(() {
    AlloyInspector.enable();
    return true;
  }());

  runApp(const GalleryApp());
}
