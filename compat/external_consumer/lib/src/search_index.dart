import 'package:alloy/alloy.dart';
import 'package:alloy_external_consumer/src/database.dart';

@AlloyInit(dependsOn: [Database])
class SearchIndex implements AsyncInitializable {
  SearchIndex(this._database);

  final Database _database;

  var isBuilt = false;

  @override
  Future<void> init() async {
    if (!_database.isOpen) {
      throw StateError('SearchIndex ran before Database was open');
    }
    isBuilt = true;
  }
}
