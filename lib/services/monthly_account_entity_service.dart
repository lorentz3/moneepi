import 'package:flutter/foundation.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/dto/account_dto.dart';
import 'package:myfinance2/dto/monthly_account_summary_dto.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/monthly_account_summary.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/account_entity_service.dart';
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
    debugPrint("Updating monthly account summary: accountId=$accountId, sum=$expenseSum, month=$month, year=$year");
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
    final String query = """
      SELECT a.id AS accountId, a.icon AS accountIcon, a.name AS accountName, t.expenseAmount, t.incomeAmount, t.month, t.year
      FROM $_tableName t 
      LEFT JOIN Accounts a ON t.accountId = a.id
      WHERE $condition
      ORDER BY a.sort DESC
    """;
    final List<Map<String, dynamic>> maps = await db.rawQuery(query);
    return List.generate(maps.length, (index) => MonthlyAccountSummaryDto.fromJson(maps[index]));
  }

  static Future<List<AccountDto>> getAllAccountsWithBalance() async {
    final db = await DatabaseHelper.getDb();
    final List<Account> accountMaps = await AccountEntityService.getAllAccounts();
    // Ottieni i saldi di tutti gli account
    final List<Map<String, dynamic>> balances = await db.rawQuery('''
      SELECT 
        accountId,
        (COALESCE(SUM(incomeAmount), 0) - COALESCE(SUM(expenseAmount), 0)) as balance
      FROM $_tableName
      GROUP BY accountId
    ''');
    
    // Crea una mappa per accesso rapido ai saldi
    Map<int, double> balanceMap = {};
    for (var item in balances) {
      balanceMap[item['accountId']] = item['balance'];
    }
    
    // Crea gli AccountDto con i saldi calcolati
    List<AccountDto> accounts = accountMaps.map((account) {
      // Usa il saldo calcolato o 0.0 se non trovato
      double balance = balanceMap[account.id] ?? 0.0;
      return AccountDto.fromAccount(account, balance);
    }).toList();
    
    return accounts;
  }

  // only for debug
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName);
  }
  
}