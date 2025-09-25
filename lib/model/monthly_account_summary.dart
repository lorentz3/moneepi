class MonthlyAccountSummary {
  final int accountId;
  final int month;
  final int year;
  double? expenseAmount;
  double? incomeAmount;
  double? cumulativeBalance;

  MonthlyAccountSummary({
    required this.accountId, 
    required this.month, 
    required this.year, 
    this.expenseAmount, 
    this.incomeAmount,
    this.cumulativeBalance,
  });

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'month': month,
      'year': year,
      'expenseAmount': expenseAmount,
      'incomeAmount': incomeAmount,
      'cumulativeBalance': cumulativeBalance,
    };
  }
  
  factory MonthlyAccountSummary.fromJson(Map<String, dynamic> json) => MonthlyAccountSummary(
    accountId: json['accountId'], 
    month: json['month'],
    year: json['year'],
    expenseAmount: json['expenseAmount'],
    incomeAmount: json['incomeAmount'],
    cumulativeBalance: json['cumulativeBalance'],
  );
}
