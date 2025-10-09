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
import 'package:myfinance2/services/app_config.dart';
import 'package:myfinance2/services/monthly_account_entity_service.dart';
import 'package:myfinance2/services/monthly_category_transaction_entity_service.dart';

class TransactionEntityService {
  static const String _tableName = "Transactions";
  
  static Future<List<TransactionDto>> getMonthTransactions(int startTimestamp, int endTimestamp) async {
    return _getTransactionsBetween(startTimestamp, endTimestamp, null, null, null, null);
  }
  
  static Future<List<Transaction>?> getAllByCategoryIdAndTimestampRange(int categoryId, int startTimestamp, int endTimestamp) async {
    final db = await DatabaseHelper.getDb();
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

  static Future<List<TransactionDto>> getTransactionsWithFilters(DateTime startDate, DateTime endDate, int? accountId, int? sourceAccountId, int? categoryId, TransactionType? type) async {
    final int startTimestamp = startDate.millisecondsSinceEpoch;
    final int endTimestamp = endDate.millisecondsSinceEpoch;
    if (endTimestamp < startTimestamp) {
      return [];
    }
    return _getTransactionsBetween(startTimestamp, endTimestamp, accountId, sourceAccountId, categoryId, type);
  }

  static Future<List<TransactionDto>> _getTransactionsBetween(int startTimestamp, int endTimestamp, int? accountId, int? sourceAccountId, int? categoryId, TransactionType? type) async {
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

  static Future<MonthTotalDto> getMonthTotalDtoWithFilters(DateTime startDate, DateTime endDate, int? accountId, int? sourceAccountId, int? categoryId, TransactionType? type) async {
    final db = await DatabaseHelper.getDb();
    final int startTimestamp = startDate.millisecondsSinceEpoch;
    final int endTimestamp = endDate.millisecondsSinceEpoch;
    String andAccountId = accountId != null ? "AND accountId = $accountId" : "";
    String andSourceAccountId = sourceAccountId != null ? "AND sourceAccountId = $sourceAccountId" : "";
    String andCategoryId = categoryId != null ? "AND categoryId = $categoryId" : "";
    String andType = type != null ? "AND type = '${type.toString().split('.').last}'" : "";
    final List<Map<String, dynamic>> totals = await db.rawQuery('''
      SELECT 
          SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0.0 END) AS total_expense,
          SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0.0 END) AS total_income
      FROM $_tableName
      WHERE timestamp >= $startTimestamp AND timestamp < $endTimestamp
      $andAccountId
      $andSourceAccountId
      $andCategoryId
      $andType
    ''');
    if (totals.isNotEmpty) {
      return MonthTotalDto(totalExpense: (totals.first['total_expense'] as double?) ?? 0.0, totalIncome: (totals.first['total_income'] as double?) ?? 0.0);
    } else {
      return MonthTotalDto(totalExpense: 0, totalIncome: 0);
    }
  }

  static Future<MonthTotalDto> getPeriodTotalDto(int? month, int year) async {
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();
    final db = await DatabaseHelper.getDb();
    final int startTimestamp = DateTime(year, month ?? 1, startingDay).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(month != null ? year : year + 1, month != null ? month + 1 : 1, startingDay).millisecondsSinceEpoch;
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

  static Future<MonthTotalDto> getMonthTotalDto(int startTimestamp, int endTimestamp) async {
    final db = await DatabaseHelper.getDb();
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

  static Future<List<MonthTotalDto>> getMonthTotals(int year) async {
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();
    final db = await DatabaseHelper.getDb();

    final DateTime startDate = DateTime(year, 1, startingDay);
    final DateTime endDate = DateTime(year + 1, 1, startingDay);

    final int startTimestamp = startDate.millisecondsSinceEpoch;
    final int endTimestamp = endDate.millisecondsSinceEpoch;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT timestamp, type, amount
      FROM $_tableName
      WHERE timestamp >= $startTimestamp AND timestamp < $endTimestamp
    ''');

    List<MonthTotalDto> monthTotals = List.generate(12, (index) {
      return MonthTotalDto(
        month: index + 1,
        totalExpense: 0.0,
        totalIncome: 0.0,
      );
    });

    for (var row in results) {
      final int ts = row['timestamp'] as int;
      final double amount = (row['amount'] as num).toDouble();
      final String type = row['type'];

      final DateTime date = DateTime.fromMillisecondsSinceEpoch(ts);

      // Trova l'inizio del "mese personalizzato"
      int adjustedYear = date.year;
      int adjustedMonth = date.month;
      if (date.day < startingDay) {
        adjustedMonth -= 1;
        if (adjustedMonth == 0) {
          adjustedMonth = 12;
          adjustedYear -= 1;
        }
      }

      // Calcola l'indice rispetto al periodo richiesto
      final int monthIndex = (adjustedYear - year) * 12 + (adjustedMonth - 1);
      if (monthIndex >= 0 && monthIndex < 12) {
        final current = monthTotals[monthIndex];
        monthTotals[monthIndex] = MonthTotalDto(
          month: monthIndex + 1,
          totalExpense: current.totalExpense + (type == 'EXPENSE' ? amount : 0.0),
          totalIncome: current.totalIncome + (type == 'INCOME' ? amount : 0.0),
        );
      }
    }

    return monthTotals;
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
      where: 'accountId = ? OR sourceAccountId = ?',
      whereArgs: [accountId, accountId],
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
    if (oldCategoryId != null && (transaction.categoryId != oldCategoryId || transaction.timestamp != oldTimestamp)) {
      debugPrint("updateMonthlyCategoryTransactionSummary oldCategoryId=$oldCategoryId");
      await MonthlyCategoryTransactionEntityService.updateMonthlyCategoryTransactionSummary(oldCategoryId, oldTimestamp);
    }
    if (transaction.accountId != oldAccountId) {
      debugPrint("updateMonthlyAccountSummaries oldAccountId=$oldAccountId");
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(oldAccountId, oldTimestamp);
    }
    if (oldSourceAccountId != null && transaction.sourceAccountId != oldSourceAccountId) {
      debugPrint("updateMonthlyAccountSummaries oldSourceAccountId=$oldSourceAccountId");
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(oldSourceAccountId, oldTimestamp);
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
      await MonthlyCategoryTransactionEntityService.updateMonthlyCategoryTransactionSummary(transaction.categoryId!, transaction.timestamp);
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(transaction.accountId!, transaction.timestamp);
    } else {
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(transaction.accountId!, transaction.timestamp);
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(transaction.sourceAccountId!, transaction.timestamp);
    }
  }
  
  static Future<List<Transaction>?> getAllByCategoryIdAndMonthAndYear(int categoryId, int month, int year) async {
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();
    final db = await DatabaseHelper.getDb();
    final int startTimestamp = DateTime(year, month, startingDay).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(year, month + 1, startingDay).millisecondsSinceEpoch;
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
    debugPrint("loaded transaction: ${maps[0]}");
    return Transaction.fromJson(maps[0]);
  }

  static Future<List<Transaction>?> getAllByAccountIdAndMonthAndYear(int accountId, int month, int year) async {
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();
    final db = await DatabaseHelper.getDb();
    final int startTimestamp = DateTime(year, month, startingDay).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(year, month + 1, startingDay).millisecondsSinceEpoch;
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
  
  /*static Future<List<Transaction>> getAllTransactionsBetween(int? startTimestamp, int? endTimestamp) async {
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
  }*/

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

  static Future<Transaction?> findFirstTransactionByCategoryId(int categoryId) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName, 
      where: "categoryId = ?",
      orderBy: "timestamp",
      limit: 1,
      whereArgs: [categoryId]
    );
    if(maps.isEmpty){
      return null;
    }
    return Transaction.fromJson(maps[0]);
  }

  static Future<Transaction?> findLastTransactionByCategoryId(int categoryId) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName, 
      where: "categoryId = ?",
      orderBy: "timestamp DESC",
      limit: 1,
      whereArgs: [categoryId]
    );
    if(maps.isEmpty){
      return null;
    }
    return Transaction.fromJson(maps[0]);
  }

  static Future<Transaction?> findFirstTransactionByAccountId(int accountId) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName, 
      where: "accountId = ?",
      orderBy: "timestamp",
      limit: 1,
      whereArgs: [accountId]
    );
    if(maps.isEmpty){
      return null;
    }
    return Transaction.fromJson(maps[0]);
  }

  static Future<Transaction?> findLastTransactionByAccountId(int accountId) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName, 
      where: "accountId = ?",
      orderBy: "timestamp DESC",
      limit: 1,
      whereArgs: [accountId]
    );
    if(maps.isEmpty){
      return null;
    }
    return Transaction.fromJson(maps[0]);
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