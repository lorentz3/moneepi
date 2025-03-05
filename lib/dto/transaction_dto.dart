import 'package:myfinance2/model/transaction_type.dart';

class TransactionDto {
  final int? id;
  final TransactionType type;
  DateTime timestamp;
  String? accountIcon;
  String accountName;
  String? categoryIcon;
  String categoryName;
  double amount;

  TransactionDto({this.id, required this.type, required this.timestamp, this.accountIcon, required this.accountName, this.categoryIcon,
    required this.categoryName, required this.amount});
  
  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
    id: json['id'],
    type: TransactionType.values.byName(json['type']),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']), 
    accountIcon: json['accountIcon'], 
    accountName: json['accountName'], 
    categoryIcon: json['categoryIcon'], 
    categoryName: json['categoryName'], 
    amount: json['amount'],
  );

}
