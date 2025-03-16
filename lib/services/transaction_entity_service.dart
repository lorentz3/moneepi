import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:myfinance2/database/database_helper.dart';
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
    return getTransactionsBetween(startTimestamp, endTimestamp);
  }
    
  static Future<List<TransactionDto>> getLastDaysTransactions(int daysNumber) async {
    final int startTimestamp = DateTime.now().subtract(Duration(days: daysNumber)).millisecondsSinceEpoch;
    final int endTimestamp = DateTime.now().millisecondsSinceEpoch;
    return getTransactionsBetween(startTimestamp, endTimestamp);
  }

  static Future<List<TransactionDto>> getTransactionsBetween(int startTimestamp, int endTimestamp) async {
    final db = await DatabaseHelper.getDb();
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
      ORDER BY timestamp DESC
    """
    );
    /*final List<Map<String, dynamic>> maps = await db.rawQuery("""
      SELECT t.id, t.type, t.timestamp, 
        a.icon AS accountIcon, a.name AS accountName, 
        c.icon AS categoryIcon, c.name AS categoryName, 
        t.amount
      FROM $_tableName t 
      LEFT JOIN Accounts a ON t.accountId = a.id
      LEFT JOIN Categories c ON t.categoryId = c.id
      WHERE timestamp >= $startTimestamp AND timestamp < $endTimestamp
      ORDER BY timestamp DESC
    """
    );*/
    return List.generate(maps.length, (index) => TransactionDto.fromJson(maps[index]));
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

  static Future<void> updateTransaction(Transaction transaction, int? oldAccount, int? oldCategory, DateTime? oldTimestamp) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      transaction.toMap(),
      where: "id = ?",
      whereArgs: [transaction.id]
    );
    await onTransactionChange(transaction);
    if (oldCategory != null) {
      await MonthlyCategoryTransactionEntityService.updateMonthlyCategoryTransactionSummary(oldCategory, transaction.timestamp.month, transaction.timestamp.year);
    }
    if (oldAccount != null) {
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(oldAccount, transaction.timestamp.month, transaction.timestamp.year);
    }
    if (oldCategory != null && oldAccount != null && oldTimestamp != null && DateUtils.areMonthYearEquals(oldTimestamp, transaction.timestamp)) {
      await MonthlyCategoryTransactionEntityService.updateMonthlyCategoryTransactionSummary(oldCategory, oldTimestamp.month, oldTimestamp.year);
      await MonthlyAccountEntityService.updateMonthlyAccountSummaries(oldAccount, oldTimestamp.month, oldTimestamp.year);
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