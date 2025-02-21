import 'package:myfinance2/database/database_defaults.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction_type.dart';

class CategoryEntityService {
  static const String _tableName = "Categories";
  
  static Future<List<Category>?> getAllCategories(TransactionType type) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps =  await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type.toString().split('.').last],
    );
    if(maps.isEmpty){
      return null;
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

  static getAllCategoriesWithMonthlyThreshold(TransactionType type) async {
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
}