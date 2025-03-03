import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/dto/transaction_dto.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/monthly_category_transaction_entity_service.dart';

class TransactionEntityService {
  static const String _tableName = "Transactions";
  
  static Future<List<TransactionDto>> getMonthTransactions(int month) async {
    final int startTimestamp = DateTime(DateTime.now().year, month, 1).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(DateTime.now().year, month + 1, 1).millisecondsSinceEpoch;
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
      SELECT t.id, t.type, t.timestamp, a.name AS accountName, c.name AS categoryName, t.amount
      FROM Transactions t 
      LEFT JOIN Accounts a ON t.accountId = a.id
      LEFT JOIN Categories c ON t.categoryId = c.id
      WHERE timestamp >= $startTimestamp AND timestamp < $endTimestamp
      ORDER BY timestamp DESC
    """
    );
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

  static Future<void> updateTransaction(Transaction transaction) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      transaction.toMap(),
      where: "id = ?",
      whereArgs: [transaction.id]
    );
    MonthlyCategoryTransactionEntityService.updateMonthlyCategoryTransactionSummary(transaction.categoryId!, transaction.timestamp.month, transaction.timestamp.year);
  }

  static Future<void> insertTransaction(Transaction transaction) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_tableName, 
      transaction.toMapCreate()
    );
    await MonthlyCategoryTransactionEntityService.updateMonthlyCategoryTransactionSummary(transaction.categoryId!, transaction.timestamp.month, transaction.timestamp.year);
  }

  static void deleteTransaction(Transaction transaction) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [transaction.id]
    );
    MonthlyCategoryTransactionEntityService.updateMonthlyCategoryTransactionSummary(transaction.categoryId!, transaction.timestamp.month, transaction.timestamp.year);
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
}