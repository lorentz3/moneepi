import 'package:flutter/foundation.dart';
import 'package:myfinance2/dto/currency_dto.dart';
import 'package:myfinance2/services/configuration_entity_service.dart';

class AppConfig {
  AppConfig._internal();
  static final AppConfig _instance = AppConfig._internal();
  static AppConfig get instance => _instance;

  CurrencyDto? _currency;

  Future<String> getCurrencySymbol() async {
    debugPrint("_currency: $_currency");
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
    debugPrint("clear currency cache");
    _currency = null;
  }
}
