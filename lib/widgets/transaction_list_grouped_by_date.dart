import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/transaction_dto.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/transaction_form_wizard_page.dart';

class TransactionsListGroupedByDate extends StatelessWidget {
  final List<TransactionDto> transactions;
  final String currencySymbol;
  final VoidCallback? onTransactionUpdated;
  final bool showAccountColumn;

  const TransactionsListGroupedByDate({super.key, required this.transactions, required this.currencySymbol, this.onTransactionUpdated, this.showAccountColumn = true});

  Map<DaySummaryDto, List<TransactionDto>> _groupTransactionsByDate() {
    Map<DaySummaryDto, List<TransactionDto>> groupedTransactions = {};
    for (var transaction in transactions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(transaction.timestamp.millisecondsSinceEpoch));
      DaySummaryDto ds = DaySummaryDto(dt: dateKey, totalExpense: 0);
      if (!groupedTransactions.containsKey(ds)) {
        groupedTransactions[ds] = [];
      }
      groupedTransactions[ds]!.add(transaction);
    }
    for (DaySummaryDto ds in groupedTransactions.keys) {
      double sum = groupedTransactions[ds]!.fold(0.0, (acc, obj) {
        if (obj.type == TransactionType.EXPENSE) {
          acc += obj.amount;
        }
        return acc;
      });
      ds.totalExpense = sum;
    }
    return groupedTransactions;
  }

  @override
  Widget build(BuildContext context) {
    final Color groupBgColor = Colors.blueGrey.shade100;
    final groupedTransactions = _groupTransactionsByDate();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: groupedTransactions.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con data raggruppata
            InkWell(
              onTap: () {
                final dateTime = DateTime.parse(entry.key.dt);
                final transaction = Transaction(
                  type: TransactionType.EXPENSE,
                  timestamp: dateTime,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionFormWizardPage(
                      transaction: transaction,
                      isNew: true,
                      initialDate: dateTime,
                    ),
                  ),
                ).then((_) {
                  onTransactionUpdated?.call();
                });
              },
              child: Container(
                color: groupBgColor,
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                child: Row(
                  children: [
                    Text(
                      DateFormat('EEE ').format(DateTime.parse(entry.key.dt)),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(entry.key.dt)),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                    if (entry.key.totalExpense != 0) Text(
                      entry.key.totalExpense > 0 
                        ? "  (tot: - ${entry.key.totalExpense.toStringAsFixed(2)} $currencySymbol)" 
                        : "  (tot: ${entry.key.totalExpense.toStringAsFixed(2)} $currencySymbol)",
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                TransactionDto movement = entry.value[index];
                TransactionType movementType = movement.type;
                Color rowColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                return movementType == TransactionType.TRANSFER ? _getTransferWidget(context, movement, rowColor) : _getTransactionWidget(context, movement, rowColor);
              },
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _getTransactionWidget(BuildContext context, TransactionDto movement, Color rowColor) {
    String categoryTitle = movement.categoryIcon != null ? "${movement.categoryIcon!} ${movement.categoryName}" : movement.categoryName ?? "";
    String accountTitle = movement.accountIcon != null ? movement.accountIcon! : movement.accountName[0];
    
    void _navigateToEdit({required bool startOnAmountPage}) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionFormWizardPage(
            transactionId: movement.id,
            transaction: Transaction(
              id: movement.id,
              type: movement.type,
              timestamp: movement.timestamp,
              accountId: movement.accountId,
              categoryId: movement.categoryId,
            ),
            isNew: false,
            startOnAmountPage: startOnAmountPage,
          ),
        ),
      ).then((_) {
        onTransactionUpdated?.call();
      });
    }
    
    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 15,
            child: InkWell(
              onTap: () => _navigateToEdit(startOnAmountPage: false),
              child: Text(
                categoryTitle,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: InkWell(
              onTap: () => _navigateToEdit(startOnAmountPage: true),
              child: Text(
                movement.type == TransactionType.EXPENSE
                    ? ' - ${movement.amount.toStringAsFixed(2)} $currencySymbol'
                    : ' + ${movement.amount.toStringAsFixed(2)} $currencySymbol',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: movement.type == TransactionType.EXPENSE
                      ? Color.fromARGB(255, 206, 35, 23)
                      : Color.fromARGB(255, 33, 122, 34),
                  fontWeight: FontWeight.bold,
                  fontSize: 14, 
                ),
              ),
            ),
          ),
          if (showAccountColumn) Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _navigateToEdit(startOnAmountPage: false),
              child: Text(
                accountTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _getTransferWidget(BuildContext context, TransactionDto movement, Color rowColor) {
    String sourceAccountName = movement.sourceAccountName ?? "Deleted account";
    String sourceAccountTitle = movement.sourceAccountIcon != null ? "${movement.sourceAccountName} ${movement.sourceAccountIcon!}" : sourceAccountName;
    String accountTitle = movement.accountIcon != null ? "${movement.accountIcon!} ${movement.accountName}" : movement.accountName;
    String accountTransferText = "$sourceAccountTitle → $accountTitle";
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionFormWizardPage(
              transactionId: movement.id,
              transaction: Transaction(
                id: movement.id,
                type: movement.type,
                timestamp: movement.timestamp,
                accountId: movement.accountId,
                sourceAccountId: movement.sourceAccountId,
              ),
              isNew: false,
            ),
          ),
        ).then((_) {
          onTransactionUpdated?.call();
        });
      },
      child: Container(
        color: rowColor,
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 20,
              child: Text(
                accountTransferText,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                ' ${movement.amount.toStringAsFixed(2)} $currencySymbol',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Color.fromARGB(255, 18, 28, 121),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 1,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class DaySummaryDto {
  final String dt;
  double totalExpense;

  DaySummaryDto({required this.dt, required this.totalExpense});

  @override
  bool operator ==(Object other) {
    return dt == (other as DaySummaryDto).dt;
  }

  @override
  int get hashCode => dt.hashCode;
}