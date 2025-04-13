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

  static Future<String> getCurrency() async {
    Configuration conf = await _getConfiguration(currency);
    return conf.textValue ?? "USD";
  }

  static Future<Configuration> _getConfiguration(String name) async {
    final db = await DatabaseHelper.getDb();
    final maps = await db.query(
      'Configurations',
      where: 'name = ?',
      whereArgs: [name],
    );
    debugPrint("currency loaded from db: $maps");
    return Configuration.fromJson(maps[0]); //sempre presente
  } 
  
  static Future<void> updateCurrency(String newCurrency) async {
    Configuration conf = await _getConfiguration(currency);
    conf.textValue = newCurrency;
    AppConfig.instance.clearCurrencyCache();
    _updateConfiguration(conf);
  }

  static Future<void> _updateConfiguration(Configuration configuration) async {
    final db = await DatabaseHelper.getDb();
    await db.update(_tableName, 
      configuration.toMap(),
      where: "id = ?",
      whereArgs: [configuration.id]
    );
    debugPrint("updated configuration ${configuration.name}: ${configuration.intValue} ${configuration.textValue} ${configuration.realValue}");
  }
 
}