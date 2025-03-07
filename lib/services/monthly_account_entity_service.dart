import 'package:flutter/foundation.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/dto/monthly_account_summary_dto.dart';
import 'package:myfinance2/model/monthly_account_summary.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';

class MonthlyAccountEntityService {
  static const String _tableName = "MonthlyAccountSummaries";

  static Future<void> updateMonthlyAccountSummary(int accountId, int month, int year) async {
    List<Transaction>? transactions = await TransactionEntityService.getAllByAccountIdAndMonthAndYear(accountId, month, year);
    double expenseSum = 0;
    double incomeSum = 0;
    if (transactions != null && transactions.isNotEmpty) {
      expenseSum = transactions.where((t) => t.type == TransactionType.EXPENSE).fold(0.0, (acc, obj) => acc + obj.amount!);
      incomeSum = transactions.where((t) => t.type == TransactionType.INCOME).fold(0.0, (acc, obj) => acc + obj.amount!);
    }
    debugPrint("Updating monthly account summary: accountId=$accountId, sum=$expenseSum");
    MonthlyAccountSummary? summary = await getMonthlyAccountSummary(accountId, month, year);
    if (summary == null) {
      MonthlyAccountSummary summary = MonthlyAccountSummary(
        accountId: accountId,
        month: month,
        year: year,
        expenseAmount: expenseSum,
        incomeAmount: incomeSum,
      );
      insertMonthlyAccountSummary(summary);
      return;
    }
    summary.expenseAmount = expenseSum;
    summary.incomeAmount = incomeSum;
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
    debugPrint("month $month year $year");
    final db = await DatabaseHelper.getDb();
    final String condition = month == 12 ? "t.month <= $month AND t.year = $year"
      : "(t.month <= $month AND t.year = $year) OR (t.month > $month AND t.year = ${year - 1})";
    final List<Map<String, dynamic>> maps = await db.rawQuery("""
      SELECT a.id AS accountId, a.icon AS accountIcon, a.name AS accountName, t.expenseAmount, t.incomeAmount, t.month, t.year
      FROM $_tableName t 
      LEFT JOIN Accounts a ON t.accountId = a.id
      WHERE $condition
      ORDER BY a.sort DESC
    """
    );
    return List.generate(maps.length, (index) => MonthlyAccountSummaryDto.fromJson(maps[index]));
  }
  
}