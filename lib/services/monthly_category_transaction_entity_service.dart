import 'package:flutter/foundation.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/dto/monthly_category_transaction_summary_dto.dart';
import 'package:myfinance2/model/monthly_category_transaction_summary.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';

class MonthlyCategoryTransactionEntityService {
  static const String _tableName = "MonthlyCategoryTransactionSummaries";

  static Future<void> updateMonthlyCategoryTransactionSummary(int categoryId, int month, int year) async {
    List<Transaction>? transactions = await TransactionEntityService.getAllByCategoryIdAndMonthAndYear(categoryId, month, year);
    double sum = 0;
    if (transactions != null && transactions.isNotEmpty) {
      sum = transactions.fold(0.0, (acc, obj) => acc + obj.amount!);
    }
    debugPrint("Updating monthly category summary: categoryId=$categoryId, sum=$sum");
    MonthlyCategoryTransactionSummary? summary = await getMonthlyCategoryTransactionSummary(categoryId, month, year);
    if (summary == null) {
      MonthlyCategoryTransactionSummary summary = MonthlyCategoryTransactionSummary(
        categoryId: categoryId,
        month: month,
        year: year,
        amount: sum
      );
      insertMonthlyCategoryTransactionSummary(summary);
      return;
    }
    summary.amount = sum;
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName,
      summary.toMap(),
      where: 'categoryId = ? AND month = ? AND year = ?',
      whereArgs: [categoryId, month, year],
    );
  }

  static Future<MonthlyCategoryTransactionSummary?> getMonthlyCategoryTransactionSummary(int categoryId, int month, int year) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'categoryId = ? AND month = ? AND year = ?',
      whereArgs: [categoryId, month, year],
    );
    if (maps.isEmpty) {
      return null;
    }
    return MonthlyCategoryTransactionSummary.fromJson(maps[0]);
  }

  static Future<void> insertMonthlyCategoryTransactionSummary(MonthlyCategoryTransactionSummary transaction) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_tableName, 
      transaction.toMap()
    );
  }

  static Future<void> deleteMonthlyCategoryTransactionSummary(int transactionId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [transactionId]
    );
  }

  static Future<List<MonthlyCategoryTransactionSummaryDto>> getAllMonthCategoriesSummaries(int month, int year) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.rawQuery("""
      SELECT c.id AS categoryId, c.icon AS categoryIcon, c.name AS categoryName, t.amount, t.month, t.year, c.monthThreshold
      FROM MonthlyCategoryTransactionSummaries t 
      LEFT JOIN Categories c ON t.categoryId = c.id
      WHERE t.month = $month AND t.year = $year AND c.type = 'EXPENSE'
      ORDER BY t.amount DESC
    """
    );
    return List.generate(maps.length, (index) => MonthlyCategoryTransactionSummaryDto.fromJson(maps[index]));
  }
  
}