import 'package:myfinance2/model/transaction_type.dart';

class TransactionDto {
  final int? id;
  final TransactionType type;
  DateTime timestamp;
  String accountName;
  String categoryName;
  double amount;

  TransactionDto({this.id, required this.type, required this.timestamp, required this.accountName, 
    required this.categoryName, required this.amount});
  
  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
    id: json['id'],
    type: TransactionType.values.byName(json['type']),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']), 
    accountName: json['accountName'], 
    categoryName: json['categoryName'], 
    amount: json['amount'],
  );

}
