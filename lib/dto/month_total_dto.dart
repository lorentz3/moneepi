class MonthTotalDto {
  final double totalExpense;
  final double totalIncome;

  MonthTotalDto({required this.totalExpense, required this.totalIncome});
 
  factory MonthTotalDto.fromJson(Map<String, dynamic> json) => MonthTotalDto(
    totalExpense: json['totalExpense'], 
    totalIncome: json['totalIncome'],
  );
}