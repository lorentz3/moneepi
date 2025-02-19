import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/dto/transaction_dto.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/accounts_page.dart';
import 'package:myfinance2/pages/categories_page.dart';
import 'package:myfinance2/pages/transaction_form_page.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFinance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TransactionDto> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    transactions = await TransactionEntityService.getMonthTransactions(
      DateTime.now().month,
    );
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    //double width = 300;
    //if (mounted) width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyFinance'),
        actions: [
          PopupMenuButton(
            onSelected: (value) => _handleClick(value, context),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: "Accounts",
                    child: Text("Accounts"),
                  ),
                  const PopupMenuItem(
                    value: "ExpenseCategories",
                    child: Text("Expense categories"),
                  ),
                  const PopupMenuItem(
                    value: "IncomeCategories",
                    child: Text("Income categories"),
                  ),
                ],
          ),
        ],
      ),
      body: _getMainBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
          ).then((_) => setState(() {
            _loadTransactions();
          }));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  _handleClick(String value, BuildContext context) {
    switch (value) {
      case "Accounts":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountsPage()),
        ).then((_) => setState(() {}));
        break;
      case "ExpenseCategories":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    const CategoriesPage(type: TransactionType.EXPENSE),
          ),
        ).then((_) => setState(() {}));
        break;
      case "IncomeCategories":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    const CategoriesPage(type: TransactionType.INCOME),
          ),
        ).then((_) => setState(() {}));
        break;
    }
  }

  _getMainBody() {
    final groupedTransactions = _groupTransactionsByDate();
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : transactions.isEmpty
        ? Center(
          child: Text(
            'Welcome to your new personal finance app! Start by configuring your accounts and categories, and then add your transactions!',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        )
        : ListView(
            children: groupedTransactions.entries.map((entry) {
              // int index = groupedTransactions.keys.toList().indexOf(entry.key);
              Color groupBgColor = Colors.blue.shade100;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: groupBgColor,
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('EEE ').format(DateTime.parse(entry.key)),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(DateTime.parse(entry.key)),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ]
                    )
                  ),
                  ...entry.value.asMap().entries.map((e) {
                    int itemIndex = e.key;
                    TransactionDto transaction = e.value;
                    Color rowColor = itemIndex % 2 == 0 ? Colors.white : Colors.grey[200]!;
                    return Container(
                      color: rowColor,
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(flex: 15, child: Text(transaction.categoryName, textAlign: TextAlign.left)),
                          Expanded(
                            flex: 10, 
                            child: Text(
                              transaction.type == TransactionType.EXPENSE
                                  ? ' - € ${transaction.amount.toStringAsFixed(2)} '
                                  : ' + € ${transaction.amount.toStringAsFixed(2)} ',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: transaction.type == TransactionType.EXPENSE ? const Color.fromARGB(255, 146, 31, 23) : const Color.fromARGB(255, 19, 65, 20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(flex: 3, child: Text(transaction.accountName.split(" ")[0], textAlign: TextAlign.center)),
                        ],
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          );
  }

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
}
