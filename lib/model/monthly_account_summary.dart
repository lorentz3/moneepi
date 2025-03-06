class MonthlyAccountSummary {
  final int accountId;
  final int month;
  final int year;
  double? amount;

  MonthlyAccountSummary({required this.accountId, required this.month, required this.year, 
    this.amount});

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'month': month,
      'year': year,
      'amount': amount,
    };
  }
  
  factory MonthlyAccountSummary.fromJson(Map<String, dynamic> json) => MonthlyAccountSummary(
    accountId: json['accountId'], 
    month: json['month'],
    year: json['year'],
    amount: json['amount'],
  );
}
