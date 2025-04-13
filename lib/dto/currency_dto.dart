class CurrencyDto {
  final String code;   // es. "EUR"
  final String symbol; // es. "€"
  final String name;   // es. "Euro"

  const CurrencyDto({required this.code, required this.symbol, required this.name});
  
  static const List<CurrencyDto> availableCurrencies = [
    CurrencyDto(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyDto(code: 'USD', symbol: '\$', name: 'US Dollar'),
    CurrencyDto(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyDto(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    CurrencyDto(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
    // ...aggiungi le valute che vuoi supportare
  ];
}