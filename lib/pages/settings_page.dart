import 'package:flutter/material.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/accounts_page.dart';
import 'package:myfinance2/pages/categories_page.dart';
import 'package:myfinance2/pages/monthly_threshold_page.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/widgets/square_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool _hasAccounts = true;
  bool _hasExpenseCategories = true;
  bool _hasIncomeCategories = true;

  @override
  void initState() {
    super.initState();
    _updateButtonFlags();
  }

  _updateButtonFlags() async {
    _hasAccounts = await AccountEntityService.existsAtLeastOneAccount();
    _hasExpenseCategories = await CategoryEntityService.existsAtLeastOneCategoryByType(TransactionType.EXPENSE);
    _hasIncomeCategories = await CategoryEntityService.existsAtLeastOneCategoryByType(TransactionType.INCOME);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double buttonSize = (MediaQuery.of(context).size.width - 32) / 4; // 32 = 8 padding per lato * 4

    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            SquareButton(
              label: "Accounts",
              icon: Icons.account_balance,
              size: buttonSize,
              highlight: !_hasAccounts,
              highlightText: "Set your accounts!",
              onPressed: () => _navigateToAccounts(context),
            ),
            SquareButton(
              label: "Expense Categories", 
              icon: Icons.category_outlined,
              size: buttonSize,
              highlight: !_hasExpenseCategories,
              highlightText: "Set your categories!",
              onPressed: () => _navigateToCategory(context, TransactionType.EXPENSE)),
            SquareButton(
              label: "Income Categories",
              icon: Icons.category,
              size: buttonSize,
              highlight: !_hasIncomeCategories,
              highlightText: "Set your categories!", 
              onPressed: () => _navigateToCategory(context, TransactionType.INCOME)),
            SquareButton(
              label: "Monthly Thresholds",
              icon: Icons.data_thresholding_outlined,
              size: buttonSize,
              highlight: false,
              highlightText: "",
              onPressed: () => _navigateToMonthlyThresholdPage(context),
            ),
            SquareButton(
              label: "Categories Groups",
              icon: Icons.group_work_outlined,
              size: buttonSize,
              highlight: false,
              highlightText: "",
              onPressed: () => _navigateToMonthlyThresholdPage(context),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAccounts(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AccountsPage()),
    ).then((_) {
      _updateButtonFlags();
    });
  }
    
  void _navigateToCategory(BuildContext context, TransactionType transactionType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoriesPage(type: transactionType,)),
    ).then((_) {
      _updateButtonFlags();
    });
  }

  void _navigateToMonthlyThresholdPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MonthlyThresholdsPage()),
    );
  }
} 