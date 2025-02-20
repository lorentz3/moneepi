class MonthlyCategoryTransactionSummaryDto {
  final String categoryName;
  final int month;
  final int year;
  double? amount;
  double? monthThreshold;

  MonthlyCategoryTransactionSummaryDto({required this.categoryName, required this.month, required this.year, 
    this.amount, this.monthThreshold});
  
  factory MonthlyCategoryTransactionSummaryDto.fromJson(Map<String, dynamic> json) => MonthlyCategoryTransactionSummaryDto(
    categoryName: json['categoryName'], 
    month: json['month'],
    year: json['year'],
    amount: json['amount'],
    monthThreshold: json['monthThreshold'],
  );
}
