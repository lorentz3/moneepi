import 'package:flutter/foundation.dart';
import 'package:myfinance2/dto/currency_dto.dart';
import 'package:myfinance2/services/configuration_entity_service.dart';

class AppConfig {
  AppConfig._internal();
  static final AppConfig _instance = AppConfig._internal();
  static AppConfig get instance => _instance;

  CurrencyDto? _currency;
  double? _monthlySaving;
  int? _periodStartingDay;

  Future<String> getCurrencySymbol() async {
    if (_currency != null) return _currency!.symbol;
    String currencyCode = await ConfigurationEntityService.getCurrency();
    _currency = CurrencyDto.availableCurrencies.firstWhere((c) => c.code == currencyCode);
    return _currency!.symbol;
  }
  
  Future<String> getCurrencyCode() async {
    if (_currency != null) return _currency!.code;
    String currencyCode = await ConfigurationEntityService.getCurrency();
    _currency = CurrencyDto.availableCurrencies.firstWhere((c) => c.code == currencyCode);
    return _currency!.code;
  }

  void clearCurrencyCache() {
    _currency = null;
  }

  Future<double> getMonthlySaving() async {
    if (_monthlySaving != null) return _monthlySaving!;
    _monthlySaving = await ConfigurationEntityService.getMonthlySaving();
    return _monthlySaving ?? 0.0;
  }

  void updateMonthlySavingCache(double? monthlySavingAmount) {
    _monthlySaving = null;
    debugPrint("updated _monthlySaving=$_monthlySaving");
  }

  Future<int> getPeriodStartingDay() async {
    if (_periodStartingDay != null) return _periodStartingDay!;
    _periodStartingDay = await ConfigurationEntityService.getPeriodStartingDay();
    return _periodStartingDay ?? 1;
  }

  void updatePeriodStartingDayCache(int? periodStartingDay) {
    _periodStartingDay = periodStartingDay ?? 1;
    debugPrint("updated periodStartingDay=$_periodStartingDay");
  }
}
