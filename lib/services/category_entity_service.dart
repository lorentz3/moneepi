import 'package:myfinance2/database/database_defaults.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';

class CategoryEntityService {
  static const String _tableName = "Categories";
  
  static Future<List<Category>> getAllCategories(CategoryType type) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps =  await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type.toString().split('.').last],
    );
    if(maps.isEmpty){
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
    final List<Map<String, dynamic>> maps =  await db.query(
      _tableName,
      where: 'type = ? AND monthThreshold IS NOT NULL',
      whereArgs: [type.toString().split('.').last],
    );
    if(maps.isEmpty){
      return [];
    }
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

  // only for debug
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName);
  }
}