import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

/// Web implementation — sets the database factory to use FFI web
void setupWebDatabase() {
  databaseFactory = databaseFactoryFfiWeb;
}
