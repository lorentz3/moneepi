import 'package:myfinance2/database/database_defaults.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/account.dart';

class AccountEntityService {
  static const String _tableName = "Accounts";
  
  static Future<List<Account>> getAllAccounts() async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    if(maps.isEmpty){
      return [];
    }
    return List.generate(maps.length, (index) => Account.fromJson(maps[index]));
  } 

  static void updateAccount(Account account) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      account.toMap(),
      where: "id = ?",
      whereArgs: [account.id]
    );
  }

  static void insertAccount(Account account) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_tableName, 
      account.toMapCreate()
    );
  }

  static void deleteAccount(int accountId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "id = ?",
      whereArgs: [accountId]
    );
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

  // only for debug
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName);
  }

}