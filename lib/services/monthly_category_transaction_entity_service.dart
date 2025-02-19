import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/monthly_category_transaction_summary.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';

class MonthlyCategoryTransactionEntityService {
  static const String _tableName = "MonthlyCategoryTransactionSummaries";

  static void updateMonthlyCategoryTransactionSummary(int categoryId, int month, int year) async {
    List<Transaction>? transactions = await TransactionEntityService.getAllByCategoryIdAndMonthAndYear(categoryId, month, year);
    if (transactions == null || transactions.isEmpty) {
      return;
    }
    double sum = transactions.fold(0.0, (acc, obj) => acc + obj.amount!);
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

  static void insertMonthlyCategoryTransactionSummary(MonthlyCategoryTransactionSummary transaction) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_tableName, 
      transaction.toMapCreate()
    );
  }

  static void deleteMonthlyCategoryTransactionSummary(int transactionId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [transactionId]
    );
  }
  
}