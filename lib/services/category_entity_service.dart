import 'package:flutter/material.dart';
import 'package:myfinance2/database/database_defaults.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';

class CategoryEntityService {
  static const String _tableName = "Categories";
  
  static Future<List<Category>?> getAllCategories() async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    if(maps.isEmpty){
      return null;
    }
    debugPrint("loaded: categories=$maps");
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
  
  static void insertDefaultCategories() async {
    final db = await DatabaseHelper.getDb();
    debugPrint('Inserting default categories');
    await db.execute(insertDefaultCategoriesQuery);
  }
}