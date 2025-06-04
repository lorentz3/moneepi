import 'package:flutter/widgets.dart';
import 'package:myfinance2/database/database_defaults.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/services/monthly_account_entity_service.dart';

class AccountEntityService {
  static const String _tableName = "Accounts";
  
  static Future<List<Account>> getAllAccounts() async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    if(maps.isEmpty){
      return [];
    }
    debugPrint("Accounts: $maps");
    return List.generate(maps.length, (index) => Account.fromJson(maps[index]));
  } 
  
  static Future<Account?> getAccountByName(String name) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName, 
      where: "name = ?",
      limit: 1,
      whereArgs: [name]
    );
    if (maps.isEmpty) {
      return null;
    }
    return Account.fromJson(maps[0]);
  }

  static Future<void> updateAccount(Account account) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      account.toMap(),
      where: "id = ?",
      whereArgs: [account.id]
    );
    await MonthlyAccountEntityService.updateAllCumulativeBalances(account.id!);
  }

  static Future<int> insertAccount(Account account) async {
    final db = await DatabaseHelper.getDb();
    return await db.insert(_tableName, 
      account.toMapCreate()
    );
  }

  static void deleteAccount(int accountId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [accountId]
    );
    await MonthlyAccountEntityService.deleteSummaries(accountId);
  }
  
  static void insertDefaultAccounts() async {
    final db = await DatabaseHelper.getDb();
    await db.execute(insertDefaultAccountsQuery);
  }

  static Future<bool> existsAtLeastOneAccount() async {
    final db = await DatabaseHelper.getDb();
    final result = await db.rawQuery('SELECT 1 FROM $_tableName LIMIT 1');
    return result.isNotEmpty;
  }

  static Future<double?> getAccountInitialBalanceById(int accountId) async {
    final db = await DatabaseHelper.getDb();

    final result = await db.rawQuery(
      "SELECT initialBalance FROM $_tableName WHERE id = ? LIMIT 1",
      [accountId]
    );

    return result.isNotEmpty ? (result.first['initialBalance'] as double?) : null;
  }

  static Future<bool> multipleAccountExist() async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT id FROM $_tableName LIMIT 2"
    );
    if (maps.isEmpty || maps.length == 1) {
      return false;
    }
    return true;
  }

  // only for debug
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName);
  }
}