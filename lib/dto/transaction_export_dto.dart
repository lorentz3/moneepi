class TransactionExportDto {
  final DateTime date;
  final String type;
  final String? account;
  final String? sourceAccount;
  final String? category;
  final double amount;
  final String? notes;

  TransactionExportDto({
    required this.date,
    required this.type,
    this.account,
    this.sourceAccount,
    this.category,
    required this.amount,
    this.notes,
  });
}