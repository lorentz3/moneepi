import 'package:flutter/foundation.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/dto/account_dto.dart';
import 'package:myfinance2/dto/monthly_account_summary_dto.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/monthly_account_summary.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/app_config.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/utils/date_utils.dart';

class MonthlyAccountEntityService {
  static const String _tableName = "MonthlyAccountSummaries";

  static Future<void> recalculateAllMonthlyAccountSummaries() async {
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();
    debugPrint("recalculate all monthly account summaries for new starting day: $startingDay");
    final List<Account> accounts = await AccountEntityService.getAllAccounts();
    for (Account account in accounts) {
      int accountId = account.id!;
      Transaction? transaction = await TransactionEntityService.findFirstTransactionByAccountId(accountId);
      if (transaction == null) {
        continue;
      }
      int transactionDay = transaction.timestamp.day;
      int transactionMonth = transaction.timestamp.month;
      int transactionYear = transaction.timestamp.year;
      if (transactionDay < startingDay) {
        transactionYear = MyDateUtils.getPreviousYear(transactionMonth, transactionYear);
        transactionMonth = MyDateUtils.getPreviousMonth(transactionMonth);
      }
      debugPrint("Start recalc account summaries: accountId=$accountId, accountName=${account.name}, from $transactionYear/$transactionMonth");
      await updateMonthlyAccountSummaries(accountId, transactionMonth, transactionYear);
    }
  }

  static const String _totalsQuery = '''
      SELECT 
        COALESCE(SUM(
          CASE 
            WHEN type = 'EXPENSE' OR (type = 'TRANSFER' AND sourceAccountId = ?) 
            THEN amount 
            ELSE 0.0 
          END
        ), 0.0) AS totalExpenses,
        
        COALESCE(SUM(
          CASE 
            WHEN type = 'INCOME' OR (type = 'TRANSFER' AND accountId = ?) 
            THEN amount 
            ELSE 0.0 
          END
        ), 0.0) AS totalIncome
      FROM Transactions
      WHERE (accountId = ? OR sourceAccountId = ?) 
        AND timestamp >= ? 
        AND timestamp < ?
    ''';

  static Future<void> updateMonthlyAccountSummaries(int accountId, int month, int year) async {
    debugPrint("Updating account summary: accountId=$accountId, $month/$year");
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();
    final db = await DatabaseHelper.getDb();
    final int startTimestamp = DateTime(year, month, startingDay).millisecondsSinceEpoch;
    final int endTimestamp = DateTime(year, month + 1, startingDay).millisecondsSinceEpoch;

    // Calcoliamo direttamente i totali dal database
    final result = await db.rawQuery(_totalsQuery, [accountId, accountId, accountId, accountId, startTimestamp, endTimestamp]);

    double expenseAmount = (result.first['totalExpenses'] as double?) ?? 0;
    double incomeAmount = (result.first['totalIncome'] as double?) ?? 0;
    debugPrint("total MonthlyAccountSummary $accountId: $month/$year, +$incomeAmount -$expenseAmount");

    // Recuperiamo il saldo cumulativo del mese precedente
    final previousBalanceResult = await db.rawQuery('''
      SELECT cumulativeBalance FROM MonthlyAccountSummaries
      WHERE accountId = ? AND month = ? AND year = ?
    ''', [accountId, (month == 1 ? 12 : month - 1), (month == 1 ? year - 1 : year)]);

    double previousBalance = 0;
    if (previousBalanceResult.isNotEmpty) {
      previousBalance = (previousBalanceResult.first['cumulativeBalance'] as double?) ?? 0;
    } else {
      previousBalance = await AccountEntityService.getAccountInitialBalanceById(accountId) ?? 0;
    }

    double cumulativeBalance = previousBalance + incomeAmount - expenseAmount;
    await insertOrUpdateMonthlyAccountSummary(accountId, month, year, previousBalance, cumulativeBalance, expenseAmount, incomeAmount);

    Transaction? lastTransaction = await TransactionEntityService.findLastTransactionByAccountId(accountId);
    if (lastTransaction == null) {
      return;
    }
    int lastMonth = lastTransaction.timestamp.month;
    int lastYear = lastTransaction.timestamp.year;
    if (MyDateUtils.isBeforeOrEqual(month, year, lastMonth, lastYear)) {
      // update in cascata dei cumulative balance dei mesi successivi
      await updateCumulativeBalances(accountId, MyDateUtils.getNextMonth(month), MyDateUtils.getNextYear(month, year));
    }
  }

  static Future<void> updateCumulativeBalances(int accountId, int startMonth, int startYear) async {
    final db = await DatabaseHelper.getDb();
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();

    // Otteniamo il saldo finale del mese precedente
    final previousBalanceResult = await db.rawQuery('''
      SELECT cumulativeBalance FROM MonthlyAccountSummaries
      WHERE accountId = ? AND month = ? AND year = ?
    ''', [accountId, (startMonth == 1 ? 12 : startMonth - 1), (startMonth == 1 ? startYear - 1 : startYear)]);

    double previousBalance = 0;
    if (previousBalanceResult.isNotEmpty) {
      previousBalance = (previousBalanceResult.first['cumulativeBalance'] as double?) ?? 0;
    } else {
      previousBalance = await AccountEntityService.getAccountInitialBalanceById(accountId) ?? 0;
      debugPrint("previousBalance is empty, replaced with account initial balance $previousBalance");
    }

    // Cicliamo dal mese successivo fino ad oggi
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    int month = startMonth;
    int year = startYear;

    while (year < currentYear || (year == currentYear && month <= currentMonth)) {
      final int startTimestamp = DateTime(year, month, startingDay).millisecondsSinceEpoch;
      final int endTimestamp = DateTime(year, month + 1, startingDay).millisecondsSinceEpoch;
      // Calcoliamo le transazioni del mese corrente
      final result = await db.rawQuery(_totalsQuery, [accountId, accountId, accountId, accountId, startTimestamp, endTimestamp]);

      double expenseAmount = (result.first['totalExpenses'] as double?) ?? 0;
      double incomeAmount = (result.first['totalIncome'] as double?) ?? 0;
      double cumulativeBalance = previousBalance + incomeAmount - expenseAmount;

      // Aggiorniamo il mese corrente
      await insertOrUpdateMonthlyAccountSummary(accountId, month, year, previousBalance, cumulativeBalance, expenseAmount, incomeAmount);

      // Il saldo di questo mese diventa il saldo precedente per il prossimo ciclo
      previousBalance = cumulativeBalance;

      // Avanziamo al mese successivo
      if (month == 12) {
        month = 1;
        year++;
      } else {
        month++;
      }
    }
  }

  static Future<void> insertOrUpdateMonthlyAccountSummary(int accountId, int month, int year, double previousBalance, double cumulativeBalance,
      double expenseAmount, double incomeAmount) async {
    final db = await DatabaseHelper.getDb();
    MonthlyAccountSummary? summary = await getMonthlyAccountSummary(accountId, month, year);
    if (summary == null) {
      MonthlyAccountSummary summary = MonthlyAccountSummary(
        accountId: accountId,
        month: month,
        year: year,
        expenseAmount: expenseAmount,
        incomeAmount: incomeAmount,
        cumulativeBalance: cumulativeBalance,
      );
      debugPrint("insert MonthlyAccountSummary $accountId: $month/$year, +$incomeAmount -$expenseAmount, cumulative:$cumulativeBalance");
      insertMonthlyAccountSummary(summary);
      return;
    }
    summary.expenseAmount = expenseAmount;
    summary.incomeAmount = incomeAmount;
    summary.cumulativeBalance = cumulativeBalance;
    debugPrint("update MonthlyAccountSummary $accountId: $month/$year, +$incomeAmount -$expenseAmount, cumulative:$cumulativeBalance");
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

  static Future<void> deleteSummariesOfDeletedAccount() async {
    final db = await DatabaseHelper.getDb();
    final String query = """
      DELETE FROM $_tableName
      WHERE accountId NOT IN (SELECT id FROM Accounts)
    """;
    await db.rawQuery(query);
  }

  static Future<void> deleteSummaries(int accountId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "accountId = ?",
      whereArgs: [accountId]
    );
  }

  static Future<List<MonthlyAccountSummaryDto>> getLast12MonthsAccountsSummaries(int month, int year) async {
    final db = await DatabaseHelper.getDb();
    final String condition = month == 12 ? "t.month <= $month AND t.year = $year"
      : "(t.month <= $month AND t.year = $year) OR (t.month > $month AND t.year = ${year - 1})";
    final String query = """
      SELECT a.id AS accountId, a.icon AS accountIcon, a.name AS accountName, t.expenseAmount, t.incomeAmount, t.cumulativeBalance, t.month, t.year
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
    
    // Crea una mappa per accesso rapido ai balance
    Map<int, double> balanceMap = {};
    for (var item in balances) {
      balanceMap[item['accountId']] = item['balance'];
    }
    
    // Crea gli AccountDto con i saldi calcolati
    List<AccountDto> accounts = accountMaps.map((account) {
      // Usa il saldo calcolato o 0.0 se non trovato
      double balance = balanceMap[account.id] ?? 0.0;
      balance += account.initialBalance;
      return AccountDto.fromAccount(account, balance);
    }).toList();
    
    return accounts;
  }

  static Future<void> updateAllCumulativeBalances(int accountId) async {
    MonthlyAccountSummary? oldest = await getOldestMonthlySummary(accountId);
    if (oldest != null) {
      updateMonthlyAccountSummaries(accountId, oldest.month, oldest.year);
    }
  }

  static Future<MonthlyAccountSummary?> getOldestMonthlySummary(int accountId) async {
    final db = await DatabaseHelper.getDb();

    final result = await db.rawQuery(
      """
      SELECT * FROM MonthlyAccountSummaries
      WHERE accountId = $accountId
      ORDER BY year ASC, month ASC
      LIMIT 1
      """
    );

    return result.isNotEmpty ? MonthlyAccountSummary.fromJson(result.first) : null;
  }

  // only for debug
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName);
  }
  
}