import 'package:myfinance2/model/transaction_type.dart';

class TransactionDto {
  final int? id;
  final TransactionType type;
  DateTime timestamp;
  int? accountId;
  String? accountIcon;
  String accountName;
  int? categoryId;
  String? categoryIcon;
  String? categoryName;
  double amount;
  int? sourceAccountId;
  String? sourceAccountIcon;
  String? sourceAccountName;

  TransactionDto({this.id, required this.type, required this.timestamp, this.accountId, this.accountIcon, required this.accountName, this.categoryId, this.categoryIcon,
    this.categoryName, required this.amount, this.sourceAccountId, this.sourceAccountIcon, this.sourceAccountName});
  
  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
    id: json['id'],
    type: TransactionType.values.byName(json['type']),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']), 
    accountId: json['accountId'],
    accountIcon: json['accountIcon'], 
    accountName: json['accountName'], 
    categoryId: json['categoryId'],
    categoryIcon: json['categoryIcon'], 
    categoryName: json['categoryName'], 
    sourceAccountId: json['sourceAccountId'],
    sourceAccountIcon: json['sourceAccountIcon'], 
    sourceAccountName: json['sourceAccountName'], 
    amount: json['amount'],
  );

}
