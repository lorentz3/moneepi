import 'package:flutter/material.dart';
import 'package:myfinance2/database/database_helper.dart';
import 'package:myfinance2/model/configuration.dart';
import 'package:myfinance2/services/app_config.dart';

class ConfigurationEntityService {
  static const String _tableName = "Configurations";
  
  static const String currency = 'CURRENCY';
  static const String firstSetupCurrency = 'FIRST_SETUP_CURRENCY';
  static const String firstSetupAccounts = 'FIRST_SETUP_ACCOUNTS';
  static const String firstSetupExpenseCategories = 'FIRST_SETUP_EXPENSE_CATEGORIES';
  static const String firstSetupIncomeCategories = 'FIRST_SETUP_INCOME_CATEGORIES';
  static const String periodStartingDay = 'PERIOD_STARTING_DAY';
  static const String homepageShowThresholdBars = 'HOMEPAGE_SHOW_THRESHOLD_BARS';
  static const String homepageShowGroupThresholdBars = 'HOMEPAGE_SHOW_GROUP_THRESHOLD_BARS';
  static const String transactionFormBySteps = 'TRANSACTION_FORM_BY_STEPS';
  static const String monthlySaving = 'MONTHLY_SAVING';

  static Future<String> getCurrency() async {
    Configuration conf = await getConfiguration(currency);
    return conf.textValue ?? "USD";
  }
  
  static Future<double> getMonthlySaving() async {
    Configuration conf = await getConfiguration(monthlySaving);
    return conf.realValue ?? 0.0;
  }
  
  static Future<int> getPeriodStartingDay() async {
    Configuration conf = await getConfiguration(periodStartingDay);
    return conf.intValue ?? 0;
  }

  static Future<Configuration> getConfiguration(String name) async {
    final db = await DatabaseHelper.getDb();
    final maps = await db.query(
      'Configurations',
      where: 'name = ?',
      whereArgs: [name],
    );
    return Configuration.fromJson(maps[0]); //sempre presente
  } 
  
  static Future<void> updateCurrency(String newCurrency) async {
    Configuration conf = await getConfiguration(currency);
    conf.textValue = newCurrency;
    AppConfig.instance.clearCurrencyCache();
    updateConfiguration(conf);
  }

  static Future<void> updateMonthlySaving(double? monthlySavingAmount) async {
    Configuration conf = await getConfiguration(monthlySaving);
    conf.realValue = monthlySavingAmount;
    updateConfiguration(conf);
    AppConfig.instance.updateMonthlySavingCache(monthlySavingAmount);
  }

  static Future<void> updatePeriodStartingDay(int? periodStartingDayValue) async {
    Configuration conf = await getConfiguration(periodStartingDay);
    conf.intValue = periodStartingDayValue;
    updateConfiguration(conf);
    AppConfig.instance.updatePeriodStartingDayCache(periodStartingDayValue);
  }

  static Future<void> updateConfiguration(Configuration configuration) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      configuration.toMap(),
      where: "id = ?",
      whereArgs: [configuration.id]
    );
    debugPrint("updated configuration ${configuration.name}: ${configuration.intValue} ${configuration.textValue} ${configuration.realValue}");
  }
  
  //for export
  static Future<List<Configuration>> getAllConfigurations() async {
    final db = await DatabaseHelper.getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    if(maps.isEmpty){
      return [];
    }
    debugPrint("Configurations: $maps");
    return List.generate(maps.length, (index) => Configuration.fromJson(maps[index]));
  } 
}