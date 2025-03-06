import 'package:flutter/foundation.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/dto/monthly_account_summary_dto.dart';
import 'package:myfinance2/model/monthly_account_summary.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';

class MonthlyAccountEntityService {
  static const String _tableName = "MonthlyAccountSummaries";

  static Future<void> updateMonthlyAccountSummary(int accountId, int month, int year) async {
    List<Transaction>? transactions = await TransactionEntityService.getAllByAccountIdAndMonthAndYear(accountId, month, year);
    double sum = 0;
    if (transactions != null && transactions.isNotEmpty) {
      sum = transactions.fold(0.0, (acc, obj) => acc + obj.amount!);
    }
    debugPrint("Updating monthly account summary: accountId=$accountId, sum=$sum");
    MonthlyAccountSummary? summary = await getMonthlyAccountSummary(accountId, month, year);
    if (summary == null) {
      MonthlyAccountSummary summary = MonthlyAccountSummary(
        accountId: accountId,
        month: month,
        year: year,
        amount: sum
      );
      insertMonthlyAccountSummary(summary);
      return;
    }
    summary.amount = sum;
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName,
      summary.toMap(),
      where: 'accountId = ? AND month = ? AND year = ?',
      whereArgs: [accountId, month, year],
    );
  }

  static Future<MonthlyAccountSummary?> getMonthlyAccountSummary(int accountId, int month, int year) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'accountId = ? AND month = ? AND year = ?',
      whereArgs: [accountId, month, year],
    );
    if (maps.isEmpty) {
      return null;
    }
    return MonthlyAccountSummary.fromJson(maps[0]);
  }

  static Future<void> insertMonthlyAccountSummary(MonthlyAccountSummary monthlyAccountSummary) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_tableName, 
      monthlyAccountSummary.toMap()
    );
  }

  // TODO probabilmente mai usato
  static Future<void> deleteMonthlyAccountSummary(int transactionId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [transactionId]
    );
  }

  static Future<List<MonthlyAccountSummaryDto>> getAllMonthAccountsSummaries(int month, int year) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.rawQuery("""
      SELECT a.id AS accountId, a.icon AS accountIcon, a.name AS accountName, t.amount, t.month, t.year
      FROM $_tableName t 
      LEFT JOIN Accounts a ON t.accountId = a.id
      WHERE t.month = $month AND t.year = $year
      ORDER BY t.amount DESC
    """
    );
    return List.generate(maps.length, (index) => MonthlyAccountSummaryDto.fromJson(maps[index]));
  }
  
}