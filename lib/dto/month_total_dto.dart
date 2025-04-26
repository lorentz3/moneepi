class MonthTotalDto {
  final int? month;
  final double totalExpense;
  final double totalIncome;

  MonthTotalDto({required this.totalExpense, required this.totalIncome, this.month});
 
  factory MonthTotalDto.fromJson(Map<String, dynamic> json) => MonthTotalDto(
    month: json['month'], 
    totalExpense: json['totalExpense'], 
    totalIncome: json['totalIncome'],
  );
}