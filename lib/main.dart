import 'package:flutter/material.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/accounts_page.dart';
import 'package:myfinance2/pages/categories_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Finance',
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

  @override
  Widget build(BuildContext context) {
    double width = 300;
    if (mounted) width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Finance'),
        actions: [
          PopupMenuButton(
            onSelected: (value) => _handleClick(value, context),
            itemBuilder: (context) => [
              const PopupMenuItem(value: "Accounts", child: Text("Accounts")),
              const PopupMenuItem(value: "ExpenseCategories", child: Text("Expense categories")),
            ],
          )
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to your new personal finance app! Start by configuring your accounts and categories!',
          style: TextStyle(fontSize: 20),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  _handleClick(String value, BuildContext context){
    switch(value) {
      case "Accounts":
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const AccountsPage())
        ).then((_) => setState(() {}));
        break;
      case "ExpenseCategories":
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const CategoriesPage(type: TransactionType.EXPENSE,))
        ).then((_) => setState(() {}));
        break;
    }
  }
}
