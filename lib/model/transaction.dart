import 'package:myfinance2/model/transaction_type.dart';

class Transaction {
  final int? id;
  final TransactionType type;
  final DateTime timestamp;
  final int accountId;
  final int categoryId;
  final double amount;
  final double? reimbursed;
  final String? notes;

  Transaction({this.id, required this.type, required this.timestamp, required this.accountId, 
    required this.categoryId, required this.amount, this.reimbursed, this.notes});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp,
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'reimbursed': reimbursed,
      'notes': notes,
    };
  }
}
