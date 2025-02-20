class MonthlyCategoryTransactionSummary {
  final int categoryId;
  final int month;
  final int year;
  double? amount;

  MonthlyCategoryTransactionSummary({required this.categoryId, required this.month, required this.year, 
    this.amount});

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'month': month,
      'year': year,
      'amount': amount,
    };
  }
  
  factory MonthlyCategoryTransactionSummary.fromJson(Map<String, dynamic> json) => MonthlyCategoryTransactionSummary(
    categoryId: json['categoryId'], 
    month: json['month'],
    year: json['year'],
    amount: json['amount'],
  );
}
