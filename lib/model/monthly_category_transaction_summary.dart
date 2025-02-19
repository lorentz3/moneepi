class MonthlyCategoryTransactionSummary {
  final int? id;
  final int categoryId;
  final int month;
  final int year;
  double? amount;

  MonthlyCategoryTransactionSummary({this.id, required this.categoryId, required this.month, required this.year, 
    this.amount});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'month': month,
      'year': year,
      'amount': amount,
    };
  }

  Map<String, dynamic> toMapCreate() {
    return {
      'categoryId': categoryId,
      'month': month,
      'year': year,
      'amount': amount,
    };
  }
  
  factory MonthlyCategoryTransactionSummary.fromJson(Map<String, dynamic> json) => MonthlyCategoryTransactionSummary(
    id: json['id'],
    categoryId: json['categoryId'], 
    month: json['month'],
    year: json['year'],
    amount: json['amount'],
  );
}
