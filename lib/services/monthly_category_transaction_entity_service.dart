import 'package:flutter/material.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/dto/monthly_category_transaction_summary_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/monthly_category_transaction_summary.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/services/app_config.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/utils/date_utils.dart';

class MonthlyCategoryTransactionEntityService {
  static const String _tableName = "MonthlyCategoryTransactionSummaries";

  static Future<void> recalculateAllMonthlyCategorySummaries() async {
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();
    debugPrint("recalculate all monthly category summaries for new starting day: $startingDay");
    final List<Category> expenseCategories = await CategoryEntityService.getAllCategories(CategoryType.EXPENSE);
    for (Category category in expenseCategories) {
      int categoryId = category.id!;
      Transaction? firstTransaction = await TransactionEntityService.findFirstTransactionByCategoryId(categoryId);
      if (firstTransaction == null) {
        continue;
      }
      int transactionMonth = firstTransaction.timestamp.month;
      int transactionYear = firstTransaction.timestamp.year;
      
      Transaction? lastTransaction = await TransactionEntityService.findLastTransactionByCategoryId(categoryId);
      if (lastTransaction == null) {
        return;
      }
      int lastMonth = lastTransaction.timestamp.month;
      int lastYear = lastTransaction.timestamp.year;

      // security margin: I calc summaries also for the month before the first and after the last
      transactionYear = MyDateUtils.getPreviousYear(transactionMonth, transactionYear);
      transactionMonth = MyDateUtils.getPreviousMonth(transactionMonth);
      lastYear = MyDateUtils.getNextYear(lastMonth, lastYear);
      lastMonth = MyDateUtils.getNextMonth(lastMonth);

      debugPrint("Start recalc category summaries: categoryId=$categoryId, caregoryName=${category.name}, from $transactionYear/$transactionMonth to $lastYear/$lastMonth");
      while (MyDateUtils.isBeforeOrEqual(transactionMonth, transactionYear, lastMonth, lastYear)) {
        await updateMonthlyCategoryTransactionSummary(categoryId, DateTime(transactionYear, transactionMonth, startingDay));
        transactionYear = MyDateUtils.getNextYear(transactionMonth, transactionYear);
        transactionMonth = MyDateUtils.getNextMonth(transactionMonth);
      }
    }
  }

  static Future<void> updateMonthlyCategoryTransactionSummary(int categoryId, DateTime transactionTimestamp) async {
    int month = transactionTimestamp.month;
    int year = transactionTimestamp.year;
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();
    if (transactionTimestamp.day < startingDay) {
      month = month - 1;
    }
    // Handle case where previous month is in the previous year
    if (month <= 0) {
      month = 12;
      year = year - 1;
    }
    
    DateTime start = DateTime(year, month, startingDay);
    DateTime end = DateTime(year, month + 1, startingDay);
    final int startTimestamp = start.millisecondsSinceEpoch;
    final int endTimestamp = end.millisecondsSinceEpoch;

    List<Transaction>? transactions = await TransactionEntityService.getAllByCategoryIdAndTimestampRange(categoryId, startTimestamp, endTimestamp);
    double sum = 0;
    if (transactions != null && transactions.isNotEmpty) {
      sum = transactions.fold(0.0, (acc, obj) => acc + obj.amount!);
    }
    debugPrint("transactions from $start to $end: categoryId=$categoryId, sum=$sum");
    MonthlyCategoryTransactionSummary? summary = await getMonthlyCategoryTransactionSummary(categoryId, month, year);
    if (summary == null) {
      debugPrint("Inserting monthly category summary: categoryId=$categoryId, $month/$year, sum=$sum");
      MonthlyCategoryTransactionSummary summary = MonthlyCategoryTransactionSummary(
        categoryId: categoryId,
        month: month,
        year: year,
        amount: sum
      );
      await insertMonthlyCategoryTransactionSummary(summary);
      return;
    }
    debugPrint("Updating monthly category summary: categoryId=$categoryId, $month/$year, sum=$sum");
    summary.amount = sum;
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName,
      summary.toMap(),
      where: 'categoryId = ? AND month = ? AND year = ?',
      whereArgs: [categoryId, month, year],
    );
  }

  static Future<MonthlyCategoryTransactionSummary?> getMonthlyCategoryTransactionSummary(int categoryId, int month, int year) async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'categoryId = ? AND month = ? AND year = ?',
      whereArgs: [categoryId, month, year],
    );
    if (maps.isEmpty) {
      return null;
    }
    return MonthlyCategoryTransactionSummary.fromJson(maps[0]);
  }

  static Future<void> insertMonthlyCategoryTransactionSummary(MonthlyCategoryTransactionSummary transaction) async {
    final db = await DatabaseHelper.getDb();
    await db.insert(_tableName, 
      transaction.toMap()
    );
  }

  static Future<void> deleteSummariesOfDeletedCategories() async {
    final db = await DatabaseHelper.getDb();
    final String query = """
      DELETE FROM $_tableName
      WHERE categoryId NOT IN (SELECT id FROM Categories)
    """;
    await db.rawQuery(query);
  }

  static Future<void> deleteMonthlyCategoryTransactionSummary(int categoryId) async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName, 
      where: "categoryId = ?",
      whereArgs: [categoryId]
    );
  }

  static Future<List<MonthlyCategoryTransactionSummaryDto>> getAllMonthCategoriesSummaries(int month, int year) async {
    debugPrint("getAllMonthCategoriesSummaries $month/$year");
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.rawQuery("""
      SELECT c.id AS categoryId, c.icon AS categoryIcon, c.name AS categoryName, t.amount, t.month, t.year, c.monthThreshold, c.sort
      FROM MonthlyCategoryTransactionSummaries t 
      LEFT JOIN Categories c ON t.categoryId = c.id
      WHERE t.month = $month AND t.year = $year AND c.type = 'EXPENSE'
      ORDER BY t.amount DESC
    """
    );
    return List.generate(maps.length, (index) => MonthlyCategoryTransactionSummaryDto.fromJson(maps[index]));
  }

  // only for debug
  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.getDb();
    await db.delete(_tableName);
  }
  
}