import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/group.dart';
import 'package:myfinance2/model/transaction_type.dart';

class GroupEntityService {
  static const String _tableName = "Groups";
  static const String _linksTableName = "Categories_Groups";
  
  static Future<List<Group>> getAllGroups(TransactionType type) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps =  await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type.toString().split('.').last],
    );
    if(maps.isEmpty){
      return [];
    }
    return List.generate(maps.length, (index) => Group.fromJson(maps[index]));
  } 

  static void updateGroup(Group group) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      group.toMap(),
      where: "id = ?",
      whereArgs: [group.id]
    );
  }

  static void insertGroup(Group group) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_tableName, 
      group.toMapCreate()
    );
  }

  static void deleteGroup(int groupId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [groupId]
    );
  }

  static Future<List<Group>> getAllGroupsWithMonthlyThreshold(TransactionType type) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps =  await db.query(
      _tableName,
      where: 'type = ? AND monthThreshold IS NOT NULL',
      whereArgs: [type.toString().split('.').last],
    );
    if(maps.isEmpty){
      return [];
    }
    return List.generate(maps.length, (index) => Group.fromJson(maps[index]));
  }
  
  static Future<void> linkExpenseToTag(int categoryId, int groupId) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_linksTableName, {
      'categoryId': categoryId,
      'groupId': groupId,
    });
  }

  // only for debug
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName);
  }

}