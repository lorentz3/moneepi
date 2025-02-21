class MonthlyCategoryTransactionSummaryDto {
  final int categoryId;
  final String categoryName;
  final int month;
  final int year;
  double? amount;
  double? monthThreshold;

  MonthlyCategoryTransactionSummaryDto({required this.categoryId, required this.categoryName, required this.month, required this.year, 
    this.amount, this.monthThreshold});
  
  factory MonthlyCategoryTransactionSummaryDto.fromJson(Map<String, dynamic> json) => MonthlyCategoryTransactionSummaryDto(
    categoryId: json['categoryId'], 
    categoryName: json['categoryName'], 
    month: json['month'],
    year: json['year'],
    amount: json['amount'],
    monthThreshold: json['monthThreshold'],
  );
}
