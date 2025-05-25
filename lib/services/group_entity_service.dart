import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/dto/category_summary_dto.dart';
import 'package:myfinance2/dto/group_dto.dart';
import 'package:myfinance2/dto/group_stats_dto.dart';
import 'package:myfinance2/dto/group_summary_dto.dart';
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

  static Future<List<GroupDto>> getGroupsWithMonthlyThreshold() async {
    return getGroupsWithCategories(true);
  }
  
  static Future<List<GroupDto>> getGroupsWithCategories(bool onlyThresholds) async {
    final db = await DatabaseHelper.getDb();
    String conditions = "";
    if (onlyThresholds) {
      conditions = "WHERE g.monthThreshold IS NOT NULL";
    }
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        g.id AS groupId, g.icon AS groupIcon, g.name AS groupName, g.sort AS groupSort, 
        g.monthThreshold AS groupMonthThreshold, g.yearThreshold AS groupYearThreshold,
        c.id AS categoryId, c.icon AS categoryIcon, c.name AS categoryName, c.sort AS categorySort, 
        c.monthThreshold AS categoryMonthThreshold, c.yearThreshold AS categoryYearThreshold, c.type as categoryType
      FROM Groups g
      LEFT JOIN Categories_Groups cg ON g.id = cg.groupId
      LEFT JOIN Categories c ON cg.categoryId = c.id
      $conditions
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
        groupMap[groupId]!.categories.add(Category(
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

  static Future<void> updateGroup(Group group) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      group.toMap(),
      where: "id = ?",
      whereArgs: [group.id]
    );
  }

  static Future<int> insertGroup(Group group) async {
    final db = await DatabaseHelper.getDb();
    int groupId = await db.insert(_tableName, 
      group.toMapCreate()
    );
    return groupId;
  }

  static void deleteGroup(int groupId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [groupId]
    );
    await db.delete(_linksTableName, 
      where: "groupId = ?",
      whereArgs: [groupId]
    );
  }

  static Future<void> removeCategoryFromAllGroups(int categoryId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_linksTableName, 
      where: "categoryId = ?",
      whereArgs: [categoryId]
    );
  }

  static Future<void> cleanGroupCategoryLinks() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_linksTableName, 
      where: "groupId NOT IN (SELECT id FROM $_tableName)",
    );
    await db.delete(_linksTableName, 
      where: "categoryId NOT IN (SELECT id FROM Categories)",
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

  static Future<void> updateGroupCategoriesLinks(int groupId, List<int> selectedCategoryIds) async {
    final db = await DatabaseHelper.getDb();

    // 1. Recuperiamo le categorie attualmente collegate al gruppo
    final List<Map<String, dynamic>> existingLinks = await db.query(
      _linksTableName,
      columns: ['categoryId'],
      where: 'groupId = ?',
      whereArgs: [groupId],
    );

    // Convertiamo i risultati in una lista di interi (gli ID delle categorie attualmente associate)
    List<int> existingCategoryIds = existingLinks.map((e) => e['categoryId'] as int).toList();

    // 2. Calcoliamo le differenze
    final toAdd = selectedCategoryIds.where((id) => !existingCategoryIds.contains(id)).toList();
    final toRemove = existingCategoryIds.where((id) => !selectedCategoryIds.contains(id)).toList();

    // 3. Aggiungiamo le nuove associazioni
    for (var categoryId in toAdd) {
      await db.insert(_linksTableName, {
        'categoryId': categoryId,
        'groupId': groupId,
      });
    }

    // 4. Rimuoviamo le associazioni non più presenti
    for (var categoryId in toRemove) {
      await db.delete(
        _linksTableName,
        where: 'categoryId = ? AND groupId = ?',
        whereArgs: [categoryId, groupId],
      );
    }
  }

  // only for debug
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName);
    await db.delete(_linksTableName);
  }

  static Future<List<GroupSummaryDto>> getGroupWithThresholdSummaries(int month, int year) async {
    final db = await DatabaseHelper.getDb();
    final result = await db.rawQuery('''
      SELECT 
        g.id, g.icon, g.name, g.sort, g.monthThreshold, g.yearThreshold, 
        COALESCE(SUM(mcts.amount), 0) as totalExpense
      FROM $_tableName g
      LEFT JOIN $_linksTableName cg ON g.id = cg.groupId
      LEFT JOIN MonthlyCategoryTransactionSummaries mcts
        ON cg.categoryId = mcts.categoryId AND mcts.month = $month AND mcts.year = $year
      WHERE g.monthThreshold IS NOT NULL
      GROUP BY g.id, g.icon, g.name, g.sort, g.monthThreshold, g.yearThreshold
      ORDER BY g.sort ASC;
    ''');

    List<GroupSummaryDto> groups = [];

    for (var row in result) {
        // Recupera le categorie associate al gruppo, con le rispettive spese
      final categoryResult = await db.rawQuery('''
        SELECT 
          c.id, c.icon, c.name, c.sort,
          COALESCE(mcts.amount, 0) as totalExpense
        FROM Categories c
        INNER JOIN Categories_Groups cg ON c.id = cg.categoryId
        LEFT JOIN MonthlyCategoryTransactionSummaries mcts
          ON c.id = mcts.categoryId AND mcts.month = ? AND mcts.year = ?
        WHERE cg.groupId = ?
        ORDER BY c.sort ASC;
      ''', [month, year, row['id']]);

      List<GroupCategorySummaryDto> categorySummaries = categoryResult.map((cRow) {
        return GroupCategorySummaryDto(
          id: cRow['id'] as int?,
          icon: cRow['icon'] as String?,
          name: cRow['name'] as String,
          sort: cRow['sort'] as int,
          totalExpense: (cRow['totalExpense'] as num?)?.toDouble(),
        );
      }).toList();

      groups.add(GroupSummaryDto(
        id: row['id'] as int?,
        icon: row['icon'] as String?,
        name: row['name'] as String,
        sort: row['sort'] as int,
        monthThreshold: row['monthThreshold'] as double?,
        yearThreshold: row['yearThreshold'] as double?,
        totalExpense: (row['totalExpense'] as num?)?.toDouble(),
        categories: categorySummaries,
      ));
    }

    return groups;
  }

  static Future<List<GroupStatsDto>> getGroupStats(int? month, int year) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> results = month != null ? await db.rawQuery(
      '''
      SELECT 
          g.id AS groupId, 
          g.name AS groupName, 
          g.icon AS groupIcon, 
          g.monthThreshold AS groupMonthThreshold,
          (SELECT SUM(m.amount)
          FROM Categories_Groups cg2
          JOIN Categories c2 ON cg2.categoryId = c2.id
          LEFT JOIN MonthlyCategoryTransactionSummaries m 
              ON c2.id = m.categoryId AND m.month = ? AND m.year = ?
          WHERE cg2.groupId = g.id) AS totalExpense,
          c.id AS categoryId, 
          c.name AS categoryName, 
          c.icon AS categoryIcon,
          c.sort AS categorySort, 
          c.monthThreshold AS categoryMonthThreshold, 
          c.yearThreshold AS categoryYearThreshold,
          SUM(m.amount) AS categoryTotalExpense
      FROM Groups g
      JOIN Categories_Groups cg ON g.id = cg.groupId
      JOIN Categories c ON cg.categoryId = c.id
      LEFT JOIN MonthlyCategoryTransactionSummaries m ON c.id = m.categoryId AND m.month = ? AND m.year = ?
      GROUP BY g.id, c.id
      ORDER BY totalExpense DESC, categoryTotalExpense DESC;
      ''',
      [month, year, month, year],
    ) : await db.rawQuery(
      '''
      SELECT 
          g.id AS groupId, 
          g.name AS groupName, 
          g.icon AS groupIcon, 
          g.monthThreshold AS groupMonthThreshold,
          (SELECT SUM(m.amount)
          FROM Categories_Groups cg2
          JOIN Categories c2 ON cg2.categoryId = c2.id
          LEFT JOIN MonthlyCategoryTransactionSummaries m 
              ON c2.id = m.categoryId AND m.year = ?
          WHERE cg2.groupId = g.id) AS totalExpense,
          c.id AS categoryId, 
          c.name AS categoryName, 
          c.icon AS categoryIcon,
          c.sort AS categorySort, 
          c.monthThreshold AS categoryMonthThreshold, 
          c.yearThreshold AS categoryYearThreshold,
          SUM(m.amount) AS categoryTotalExpense
      FROM Groups g
      JOIN Categories_Groups cg ON g.id = cg.groupId
      JOIN Categories c ON cg.categoryId = c.id
      LEFT JOIN MonthlyCategoryTransactionSummaries m ON c.id = m.categoryId AND m.year = ?
      GROUP BY g.id, c.id
      ORDER BY totalExpense DESC, categoryTotalExpense DESC;
      ''',
      [year, year],
    ) ;

    Map<int, List<CategorySummaryDto>> categoriesByGroup = {};
    Map<int, Map<String, dynamic>> groupData = {};
    for (var row in results) {
      int groupId = row['groupId'];
      if (!groupData.containsKey(groupId)) {
        groupData[groupId] = row;
        categoriesByGroup[groupId] = [];
      }
      categoriesByGroup[groupId]!.add(CategorySummaryDto.fromJson(row));
    }
    return groupData.entries
          .map((entry) => GroupStatsDto.fromJson(entry.value, categoriesByGroup[entry.key]!))
          .toList();
  }

  static Future<void> updateMonthThresholdById(int? groupId, double? monthThreshold) async {
    final db = await DatabaseHelper.getDb();
    await db.execute("""
      UPDATE $_tableName SET monthThreshold = $monthThreshold WHERE id = $groupId
    """);
  }

}