import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_dto.dart';

class TransactionEntityService {
  static const String _tableName = "Transactions";
  
  static Future<List<TransactionDto>> getMonthTransactions(int month) async {
    final db = await DatabaseHelper.getDb();
    final int startTimestamp = DateTime(DateTime.now().year, month, 1).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(DateTime.now().year, month + 1, 1).millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.rawQuery("""
      SELECT t.id, t.type, t.timestamp, a.name AS accountName, c.name AS categoryName, t.amount, t.reimbursed
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

  static void updateTransaction(Transaction transaction) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      transaction.toMap(),
      where: "id = ?",
      whereArgs: [transaction.id]
    );
  }

  static void insertTransaction(Transaction transaction) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_tableName, 
      transaction.toMapCreate()
    );
  }

  static void deleteTransaction(int transactionId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [transactionId]
    );
  }
  
}