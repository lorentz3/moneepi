enum TransactionType {EXPENSE, INCOME, TRANSFER}

String getTransactionTypeText(TransactionType type) {
  switch(type) {
    case TransactionType.EXPENSE: return "expense";
    case TransactionType.INCOME: return "income";
    case TransactionType.TRANSFER: return "transfer";
  }
}