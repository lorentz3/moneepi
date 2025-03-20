import 'package:flutter/material.dart';
import 'package:myfinance2/dto/movement_dto.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/transaction_form_page.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/widgets/month_selector.dart';
import 'package:myfinance2/widgets/transaction_list_grouped_by_date.dart';

class MovementsPage extends StatefulWidget {
  final DateTime dateTime;
  const MovementsPage({super.key, required this.dateTime});

  @override
  State createState() => MovementsPageState();
}

class MovementsPageState extends State<MovementsPage> {
  late DateTime selectedDate = widget.dateTime;
  List<TransactionDto> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _updateDate(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
    });
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    transactions = await TransactionEntityService.getMonthTransactions(selectedDate.month, selectedDate.year);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: MonthSelector(selectedDate: selectedDate, onDateChanged: _updateDate),
        ),
        body: transactions.isEmpty ? Center(child: const Text("Still no movements"),)
          : SingleChildScrollView(
          child: TransactionsListGroupedByDate(transactions: transactions)
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TransactionFormPage(
                      transaction: Transaction(
                        type: TransactionType.EXPENSE,
                        timestamp: DateTime.now(),
                      ),
                      isNew: true,
                    ),
              ),
            ).then((_) {
              _loadTransactions(); 
            });
          },
        child: const Icon(Icons.add),
      ),
    );
  }
} 