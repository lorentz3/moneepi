class MonthlyCategoryTransactionSummaryDto {
  final int categoryId;
  final String? categoryIcon;
  final String categoryName;
  final int month;
  final int year;
  double? amount;
  double? monthThreshold;

  MonthlyCategoryTransactionSummaryDto({required this.categoryId, this.categoryIcon, required this.categoryName, required this.month, required this.year, 
    this.amount, this.monthThreshold});
  
  factory MonthlyCategoryTransactionSummaryDto.fromJson(Map<String, dynamic> json) => MonthlyCategoryTransactionSummaryDto(
    categoryId: json['categoryId'], 
    categoryIcon: json['categoryIcon'], 
    categoryName: json['categoryName'], 
    month: json['month'],
    year: json['year'],
    amount: json['amount'],
    monthThreshold: json['monthThreshold'],
  );
}
