import 'package:myfinance2/model/transaction_type.dart';

class Transaction {
  final int? id;
  TransactionType type;
  DateTime timestamp;
  int? accountId;
  int? categoryId;
  double? amount;
  String? notes;

  Transaction({this.id, required this.type, required this.timestamp, this.accountId, 
    this.categoryId, this.amount, this.notes});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'notes': notes,
    };
  }

  Map<String, dynamic> toMapCreate() {
    return {
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'notes': notes,
    };
  }
  
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    type: TransactionType.values.byName(json['type']),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']), 
    accountId: json['accountId'], 
    categoryId: json['categoryId'], 
    amount: json['amount'],
    notes: json['notes'],
  );
}
