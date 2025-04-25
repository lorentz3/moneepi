import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/dto/month_total_dto.dart';
import 'package:myfinance2/dto/transaction_export_dto.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/dto/movement_dto.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/monthly_account_entity_service.dart';
import 'package:myfinance2/services/monthly_category_transaction_entity_service.dart';
import 'package:myfinance2/utils/date_utils.dart';

class TransactionEntityService {
  static const String _tableName = "Transactions";
  
  static Future<List<TransactionDto>> getMonthTransactions(int month, int year) async {
    final int startTimestamp = DateTime(year, month, 1).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    return getTransactionsBetween(startTimestamp, endTimestamp, null, null, null, null);
  }

  static Future<List<TransactionDto>> getMonthTransactionsWithFilters(int month, int year, int? accountId, int? sourceAccountId, int? categoryId, TransactionType? type) async {
    final int startTimestamp = DateTime(year, month, 1).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    return getTransactionsBetween(startTimestamp, endTimestamp, accountId, sourceAccountId, categoryId, type);
  }
    
  static Future<List<TransactionDto>> getLastDaysTransactions(int daysNumber) async {
    final int startTimestamp = DateTime.now().subtract(Duration(days: daysNumber)).millisecondsSinceEpoch;
    final int endTimestamp = DateTime.now().millisecondsSinceEpoch;
    return getTransactionsBetween(startTimestamp, endTimestamp, null, null, null, null);
  }

  static Future<List<TransactionDto>> getTransactionsBetween(int startTimestamp, int endTimestamp, int? accountId, int? sourceAccountId, int? categoryId, TransactionType? type) async {
    final db = await DatabaseHelper.getDb();
    String andAccountId = accountId != null ? "AND t.accountId = $accountId" : "";
    String andSourceAccountId = sourceAccountId != null ? "AND t.sourceAccountId = $sourceAccountId" : "";
    String andCategoryId = categoryId != null ? "AND t.categoryId = $categoryId" : "";
    String andType = type != null ? "AND t.type = '${type.toString().split('.').last}'" : "";
    final List<Map<String, dynamic>> maps = await db.rawQuery("""
      SELECT t.id, t.type, t.timestamp, 
        a.icon AS accountIcon, a.name AS accountName, 
        c.icon AS categoryIcon, c.name AS categoryName, 
        sourceAccounts.icon AS sourceAccountIcon, sourceAccounts.name AS sourceAccountName,
        t.amount
      FROM $_tableName t 
      LEFT JOIN Accounts a ON t.accountId = a.id
      LEFT JOIN Accounts sourceAccounts ON t.sourceAccountId = sourceAccounts.id
      LEFT JOIN Categories c ON t.categoryId = c.id
      WHERE timestamp >= $startTimestamp AND timestamp < $endTimestamp
      $andAccountId
      $andSourceAccountId
      $andCategoryId
      $andType
      ORDER BY timestamp DESC
    """
    );
    return List.generate(maps.length, (index) => TransactionDto.fromJson(maps[index]));
  }

  static Future<MonthTotalDto> getMonthTotalDto(int? month, int year) async {
    final db = await DatabaseHelper.getDb();
    final int startTimestamp = DateTime(year, month ?? 1, 1).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(month != null ? year : year + 1, month != null ? month + 1 : 1, 1).millisecondsSinceEpoch;
    final List<Map<String, dynamic>> totals = await db.rawQuery('''
      SELECT 
          SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0.0 END) AS total_expense,
          SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0.0 END) AS total_income
      FROM $_tableName
      WHERE timestamp >= $startTimestamp AND timestamp < $endTimestamp
    ''');
    if (totals.isNotEmpty) {
      return MonthTotalDto(totalExpense: (totals.first['total_expense'] as double?) ?? 0.0, totalIncome: (totals.first['total_income'] as double?) ?? 0.0);
    } else {
      return MonthTotalDto(totalExpense: 0, totalIncome: 0);
    }
  }

  static Future<bool> transactionExistsByCategoryId(int categoryId) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, Object?>> result = await db.query(
      _tableName,
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<bool> transactionExistsByAccountId(int accountId) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, Object?>> result = await db.query(
      _tableName,
      where: 'accountId = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<void> updateTransaction(Transaction transaction, int oldAccountId, int? oldCategoryId, DateTime oldTimestamp, int? oldSourceAccountId) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      transaction.toMap(),
      where: "id = ?",
      whereArgs: [transaction.id]
    );
    await onTransactionChange(transaction);

    //update old referenced summaries
    int monthToUpdate = oldTimestamp.month;
    int yearToUpdate = oldTimestamp.year;
    if (oldCategoryId != null && (transaction.categoryId != oldCategoryId || !MyDateUtils.areMonthYearEquals(transaction.timestamp, oldTimestamp))) {
      debugPrint("updateMonthlyCategoryTransactionSummary $oldCategoryId");
      await MonthlyCategoryTransactionEntityService.updateMonthlyCategoryTransactionSummary(oldCategoryId, monthToUpdate, yearToUpdate);
    }
    if (transaction.accountId != oldAccountId) {
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(oldAccountId, monthToUpdate, yearToUpdate);
    }
    if (oldSourceAccountId != null && transaction.sourceAccountId != oldSourceAccountId) {
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(oldSourceAccountId, monthToUpdate, yearToUpdate);
    }
  }

  static Future<void> insertTransaction(Transaction transaction) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_tableName, 
      transaction.toMapCreate()
    );
    await onTransactionChange(transaction);
  }

  static Future<void> deleteTransaction(Transaction transaction) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [transaction.id]
    );
    await onTransactionChange(transaction);
  }

  static Future<void> onTransactionChange(Transaction transaction) async {
    if (transaction.type != TransactionType.TRANSFER) {
      await MonthlyCategoryTransactionEntityService.updateMonthlyCategoryTransactionSummary(transaction.categoryId!, transaction.timestamp.month, transaction.timestamp.year);
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(transaction.accountId!, transaction.timestamp.month, transaction.timestamp.year);
    } else {
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(transaction.accountId!, transaction.timestamp.month, transaction.timestamp.year);
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(transaction.sourceAccountId!, transaction.timestamp.month, transaction.timestamp.year);
    }
  }
  
  static Future<List<Transaction>?> getAllByCategoryIdAndMonthAndYear(int categoryId, int month, int year) async {
    final db = await DatabaseHelper.getDb();
    final int startTimestamp = DateTime(year, month, 1).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps =  await db.query(
      _tableName,
      where: 'timestamp >= ? AND timestamp < ? AND categoryId = ?',
      whereArgs: [startTimestamp, endTimestamp, categoryId],
    );
    if(maps.isEmpty){
      return null;
    }
    return List.generate(maps.length, (index) => Transaction.fromJson(maps[index]));
  }

  static Future<Transaction> getById(int? id) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName, 
      where: "id = ?",
      whereArgs: [id]
    );
    if(maps.isEmpty){
      return Transaction(type: TransactionType.EXPENSE, timestamp: DateTime.now());
    }
    return Transaction.fromJson(maps[0]);
  }

  static Future<List<Transaction>?> getAllByAccountIdAndMonthAndYear(int accountId, int month, int year) async {
    final db = await DatabaseHelper.getDb();
    final int startTimestamp = DateTime(year, month, 1).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps =  await db.query(
      _tableName,
      where: 'timestamp >= ? AND timestamp < ? AND accountId = ?',
      whereArgs: [startTimestamp, endTimestamp, accountId],
    );
    if(maps.isEmpty){
      return null;
    }
    return List.generate(maps.length, (index) => Transaction.fromJson(maps[index]));
  }
  
  static Future<List<Transaction>> getAllTransactionsBetween(int? startTimestamp, int? endTimestamp) async {
    final db = await DatabaseHelper.getDb();
    List<Map<String, dynamic>> maps = [];
    if (startTimestamp != null && endTimestamp != null) {
      maps = await db.query(
        _tableName,
        where: 'timestamp >= ? AND timestamp < ?',
        whereArgs: [startTimestamp, endTimestamp],
      );
    } else {
      maps = await db.query(_tableName);
    }
    return List.generate(maps.length, (index) => Transaction.fromJson(maps[index]));
  }

  static Future<List<TransactionExportDto>> getTransactionsForExport({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await DatabaseHelper.getDb();
    final whereClause = (from != null && to != null)
        ? 'WHERE timestamp BETWEEN ? AND ?'
        : '';
    final whereArgs = (from != null && to != null)
        ? [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch]
        : [];

    final result = await db.rawQuery('''
      SELECT t.timestamp, t.type, t.amount, t.notes,
            a.name AS accountName,
            sa.name AS sourceAccountName,
            c.name AS categoryName
      FROM $_tableName t
      LEFT JOIN Accounts a ON a.id = t.accountId
      LEFT JOIN Accounts sa ON sa.id = t.sourceAccountId
      LEFT JOIN Categories c ON c.id = t.categoryId
      $whereClause
      ORDER BY t.timestamp DESC
    ''', whereArgs);

    return result.map((row) {
      return TransactionExportDto(
        date: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
        type: (row['type'] as String),
        account: row['accountName'] as String?,
        sourceAccount: row['sourceAccountName'] as String?,
        category: row['categoryName'] as String?,
        amount: row['amount'] as double,
        notes: row['notes'] as String?,
      );
    }).toList();
  }

  // only for debug
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName);
  }

  static Future<void> insertRandomTransactions(List<Category> expenseCategories, List<Category> incomeCategories, List<Account> accounts) async {
    // Verifica che le liste non siano vuote
    if (expenseCategories.isEmpty || incomeCategories.isEmpty || accounts.isEmpty) {
      debugPrint('Errore: Una o più liste sono vuote');
      return;
    }
    Random random = Random();

    // Scegliamo casualmente se sarà una spesa o un guadagno
    for (int i = 0; i < 200; ++i) {
      List<Category> chosenCategoryList = i > 20 ? expenseCategories : incomeCategories;

      // Selezioniamo casualmente un account e una categoria
      Account randomAccount = accounts[random.nextInt(accounts.length)];
      Category randomCategory = chosenCategoryList[random.nextInt(chosenCategoryList.length)];

      // Generiamo una data casuale nell'ultimo anno
      DateTime now = DateTime.now();
      DateTime randomTimestamp = now.subtract(Duration(days: random.nextInt(365)));

      // Generiamo un importo casuale (tra 1 e 500 per esempio)
      double randomAmount = (random.nextDouble() * 500).round() / 1;
      if (i < 20) {
        randomAmount = randomAmount * 10;
      }

      // Creiamo e salviamo la transazione
      await insertTransaction(Transaction(
        type: i > 20 ? TransactionType.EXPENSE : TransactionType.INCOME,
        timestamp: randomTimestamp,
        accountId: randomAccount.id,
        categoryId: randomCategory.id,
        amount: randomAmount,
      ));
    }
  }

}