class MonthlyAccountSummaryDto {
  final int accountId;
  final String? accountIcon;
  final String accountName;
  final int month;
  final int year;
  double? amount;

  MonthlyAccountSummaryDto({required this.accountId, this.accountIcon, required this.accountName, required this.month, required this.year, 
    this.amount});
  
  factory MonthlyAccountSummaryDto.fromJson(Map<String, dynamic> json) => MonthlyAccountSummaryDto(
    accountId: json['accountId'], 
    accountIcon: json['accountIcon'], 
    accountName: json['accountName'], 
    month: json['month'],
    year: json['year'],
    amount: json['amount'],
  );
}
