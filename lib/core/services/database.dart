
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<void> resetDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'postboy.db');

  await deleteDatabase(path);
  print('Database deleted!');
}
