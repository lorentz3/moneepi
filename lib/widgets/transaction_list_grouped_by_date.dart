import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/transaction_dto.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/transaction_form_page.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';

class TransactionsListGroupedByDate extends StatelessWidget { //TODO stateful
  final List<TransactionDto> transactions;

  const TransactionsListGroupedByDate({super.key, required this.transactions});

  Map<String, List<TransactionDto>> _groupTransactionsByDate() {
    Map<String, List<TransactionDto>> groupedTransactions = {};
    for (var transaction in transactions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(transaction.timestamp.millisecondsSinceEpoch));
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
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
            Container(
              color: groupBgColor,
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    DateFormat('EEE ').format(DateTime.parse(entry.key)),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.parse(entry.key)),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                TransactionDto transaction = entry.value[index];
                Color rowColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionFormPage(
                          transactionId: transaction.id,
                          isNew: false,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: rowColor,
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 15,
                          child: Text(
                            transaction.categoryName,
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Text(
                            transaction.type == TransactionType.EXPENSE
                                ? ' - € ${transaction.amount.toStringAsFixed(2)} '
                                : ' + € ${transaction.amount.toStringAsFixed(2)} ',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: transaction.type == TransactionType.EXPENSE
                                  ? Color.fromARGB(255, 206, 35, 23)
                                  : Color.fromARGB(255, 33, 122, 34),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            transaction.accountName.split(" ")[0],
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }
}