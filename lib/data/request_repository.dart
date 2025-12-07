import '../core/db/database_helper.dart';
import '../core/models/api_request.dart';

// class RequestRepository {
//   final dbHelper = DatabaseHelper.instance;
//
//   Future<int> insertRequest(ApiRequest request) async {
//     final db = await dbHelper.database;
//     return await db.insert('requests', request.toJson());
//   }
//
//   Future<List<ApiRequest>> getAllRequests() async {
//     final db = await dbHelper.database;
//     final result = await db.query('requests', orderBy: 'id DESC');
//     return result.map((e) => ApiRequest.fromJson(e)).toList();
//   }
//
//   Future<int> deleteRequest(int id) async {
//     final db = await dbHelper.database;
//     return await db.delete('requests', where: 'id = ?', whereArgs: [id]);
//   }
// }



typedef FromJson<T> = T Function(Map<String, dynamic> json);

class GenericRepository<T> {
  final String tableName;
  final FromJson<T> fromJson;

  final dbHelper = DatabaseHelper.instance;

  GenericRepository({
    required this.tableName,
    required this.fromJson,
  });

  Future<int> insert(Map<String, dynamic> data) async {
    final db = await dbHelper.database;
    return await db.insert(tableName, data);
  }

  Future<List<T>> getAll() async {
    final db = await dbHelper.database;
    final result = await db.query(tableName, orderBy: 'id DESC');
    return result.map((e) => fromJson(e)).toList();
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<T?> getById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return fromJson(result.first);
  }
  Future<int> update(int id, Map<String, dynamic> data) async {
    final db = await dbHelper.database;
    return await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}
