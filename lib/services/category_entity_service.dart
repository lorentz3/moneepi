import 'package:myfinance2/database/database_defaults.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/dto/category_summary_dto.dart';
import 'package:myfinance2/dto/group_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';

class CategoryEntityService {
  static const String _tableName = "Categories";
  
  static Future<List<Category>> getAllCategories(CategoryType type) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps =  await db.query(
      _tableName,
      where: 'type = ?',
      orderBy: 'sort',
      whereArgs: [type.toString().split('.').last],
    );
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (index) => Category.fromJson(maps[index]));
  } 

  static Future<List<Category>> getAllExpenseAndIncomeCategories() async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps =  await db.query(_tableName);
    if(maps.isEmpty){
      return [];
    }
    return List.generate(maps.length, (index) => Category.fromJson(maps[index]));
  } 

  static void updateCategory(Category category) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      category.toMap(),
      where: "id = ?",
      whereArgs: [category.id]
    );
  }

  static Future<List<CategorySummaryDto>> getCategoriesWithoutGroup(int? month, int year) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> categoryResults = month != null ? await db.rawQuery(
      '''
      SELECT 
        c.id AS categoryId, 
        c.icon AS categoryIcon, 
        c.name AS categoryName, 
        c.sort AS categorySort,
        m.amount AS categoryTotalExpense,
        c.monthThreshold AS categoryMonthThreshold
      FROM Categories c
      LEFT JOIN MonthlyCategoryTransactionSummaries m ON c.id = m.categoryId AND m.month = ? AND m.year = ?
      WHERE c.id NOT IN (SELECT categoryId FROM Categories_Groups)
      AND c.type != 'INCOME'
      ORDER BY categoryTotalExpense DESC, categorySort ASC;
      ''',
      [month, year],
    ) : await db.rawQuery(
      '''
      SELECT 
        c.id AS categoryId, 
        c.icon AS categoryIcon, 
        c.name AS categoryName, 
        c.sort AS categorySort,
        SUM(m.amount) AS categoryTotalExpense,
        c.monthThreshold AS categoryMonthThreshold
      FROM Categories c
      LEFT JOIN MonthlyCategoryTransactionSummaries m ON c.id = m.categoryId AND m.year = ?
      WHERE c.id NOT IN (SELECT categoryId FROM Categories_Groups)
      AND c.type != 'INCOME'
      GROUP BY c.id
      ORDER BY categoryTotalExpense DESC, categorySort ASC;
      ''',
      [year],
    );
    return List.generate(categoryResults.length, (index) => CategorySummaryDto.fromJson(categoryResults[index]));
  }

  static Future<Map<int, CategorySummaryDto>> getCategoryStats(int categoryId, int year) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> categoryResults = await db.rawQuery(
      '''
      SELECT 
        m.month AS month,
        c.id AS categoryId, 
        c.icon AS categoryIcon, 
        c.name AS categoryName, 
        c.sort AS categorySort,
        m.amount AS categoryTotalExpense,
        c.monthThreshold AS categoryMonthThreshold
      FROM Categories c
      LEFT JOIN MonthlyCategoryTransactionSummaries m ON c.id = m.categoryId AND m.year = ?
      WHERE c.id = ?
      ORDER BY categoryTotalExpense DESC, categorySort ASC;
      ''',
      [year, categoryId],
    );
    if (categoryResults.isEmpty) {
      return {};
    }
    //init
    Map<String, dynamic> cat = categoryResults[0];
    final Map<int, CategorySummaryDto> monthlyMap = {
      for (int month = 1; month <= 12; month++)
        month: CategorySummaryDto(
          id: cat['categoryId'],
          name: cat['categoryName'],
          sort: cat['categorySort'],
          icon: cat['categoryIcon'],
          monthThreshold: cat['categoryMonthThreshold'],
          totalExpense: 0.0,
        ),
    };

    for (final row in categoryResults) {
      final month = row['month'] as int?;
      if (month != null) {
        monthlyMap[month] = CategorySummaryDto.fromJson(row);
      }
    }
    return monthlyMap;
  }

  static void insertCategory(Category category) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_tableName, 
      category.toMapCreate()
    );
  }

  static void deleteCategory(int categoryId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [categoryId]
    );
  }
  
  static Future<Category> getCategoryById(int categoryId) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName, 
      where: "id = ?",
      whereArgs: [categoryId]
    );
    if (maps.isEmpty) {
      return Category(name: "Category not found", type: CategoryType.EXPENSE, sort: 1);
    }
    return Category.fromJson(maps[0]);
  }
  
  static void insertDefaultExpenseCategories() async {
    final db = await DatabaseHelper.getDb();
    await db.execute(insertDefaultExpenseCategoriesQuery);
  }
  
  static void insertDefaultIncomeCategories() async {
    final db = await DatabaseHelper.getDb();
    await db.execute(insertDefaultIncomeCategoriesQuery);
  }

  static Future<List<Category>> getAllCategoriesWithMonthlyThreshold(CategoryType type) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ? AND monthThreshold IS NOT NULL',
      whereArgs: [type.toString().split('.').last],
    );
    if(maps.isEmpty){
      return [];
    }
    return List.generate(maps.length, (index) => Category.fromJson(maps[index]));
  }
  
  static Future<List<Category>> getCategoriesWithMonthlyThresholdNotInGroups(CategoryType type, List<GroupDto> groups) async {
    // Se non ci sono gruppi, fai la query semplice
    if (groups.isEmpty) {
      return getAllCategoriesWithMonthlyThreshold(type);
    }
    final db = await DatabaseHelper.getDb();
    // Altrimenti costruisci la query con esclusione
    final groupIds = groups.map((g) => g.id).toList();
    final placeholders = List.generate(groupIds.length, (index) => '?').join(', ');

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $_tableName
      WHERE type = ?
        AND monthThreshold IS NOT NULL
        AND id NOT IN (
          SELECT categoryId
          FROM Categories_Groups
          WHERE groupId IN ($placeholders)
        )
    ''', [type.toString().split('.').last, ...groupIds]);

    return List.generate(maps.length, (index) => Category.fromJson(maps[index]));
  }

  static Future<bool> existsAtLeastOneCategoryByType(CategoryType type) async {
    final db = await DatabaseHelper.getDb();
    final typeName = type.toString().split('.').last;
    final result = await db.rawQuery('SELECT 1 FROM $_tableName WHERE type = "$typeName" LIMIT 1');
    return result.isNotEmpty;
  }

  static Future<void> updateMonthThresholdById(int? categoryId, double? monthThreshold) async {
    final db = await DatabaseHelper.getDb();
    await db.execute("""
      UPDATE $_tableName SET monthThreshold = $monthThreshold WHERE id = $categoryId
    """);
  }

  static Future<void> updateSort(List<Category> categories) async {
    final db = await DatabaseHelper.getDb();
    for (Category category in categories){
      await db.update(_tableName, 
        category.toMapSort(),
        where: "id = ?",
        whereArgs: [category.id]
      );
    }
  }

  // only for debug
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName);
  }

}