import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/dto/group_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/group.dart';
import 'package:myfinance2/model/transaction_type.dart';

class GroupEntityService {
  static const String _tableName = "Groups";
  static const String _linksTableName = "Categories_Groups";
  
  static Future<List<Group>> getAllGroups() async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps =  await db.query(_tableName);
    if(maps.isEmpty){
      return [];
    }
    return List.generate(maps.length, (index) => Group.fromJson(maps[index]));
  } 
  
  static Future<List<GroupDto>> getGroupsWithCategories() async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        g.id AS groupId, g.icon AS groupIcon, g.name AS groupName, g.sort AS groupSort, 
        g.monthThreshold AS groupMonthThreshold, g.yearThreshold AS groupYearThreshold,
        c.id AS categoryId, c.icon AS categoryIcon, c.name AS categoryName, c.sort AS categorySort, 
        c.monthThreshold AS categoryMonthThreshold, c.yearThreshold AS categoryYearThreshold, c.type as categoryType
      FROM Groups g
      LEFT JOIN Categories_Groups cg ON g.id = cg.groupId
      LEFT JOIN Categories c ON cg.categoryId = c.id
      ORDER BY g.sort, c.sort
    ''');

    Map<int, GroupDto> groupMap = {};

    for (var row in results) {
      int groupId = row['groupId'];
      if (!groupMap.containsKey(groupId)) {
        groupMap[groupId] = GroupDto(
          id: groupId,
          icon: row['groupIcon'],
          name: row['groupName'],
          sort: row['groupSort'],
          monthThreshold: row['groupMonthThreshold'],
          yearThreshold: row['groupYearThreshold'],
          categories: [],
        );
      }
      
      if (row['categoryId'] != null) {
        groupMap[groupId]!.categories!.add(Category(
          id: row['categoryId'],
          icon: row['categoryIcon'],
          name: row['categoryName'],
          type: CategoryType.values.byName(row['categoryType']),
          sort: row['categorySort'],
          monthThreshold: row['categoryMonthThreshold'],
          yearThreshold: row['categoryYearThreshold'],
        ));
      }
    }

    return groupMap.values.toList();
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