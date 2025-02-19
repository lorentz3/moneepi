import 'package:myfinance2/database/database_defaults.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/account.dart';

class AccountEntityService {
  static const String _tableName = "Accounts";
  
  static Future<List<Account>?> getAllAccounts() async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    if(maps.isEmpty){
      return null;
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
}