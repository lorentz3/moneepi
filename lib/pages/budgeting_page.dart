import 'package:flutter/material.dart';
import 'package:myfinance2/pages/monthly_threshold_page.dart';
import 'package:myfinance2/widgets/square_button.dart';

class BudgetingPage extends StatefulWidget {
  const BudgetingPage({super.key});

  @override
  State createState() => BudgetingPageState();
}

class BudgetingPageState extends State<BudgetingPage> {

  @override
  void initState() {
    super.initState();
    //_updateButtonFlags();
  }

  /*_updateButtonFlags() async {
    _hasAccounts = await AccountEntityService.existsAtLeastOneAccount();
    _hasExpenseCategories = await CategoryEntityService.existsAtLeastOneCategoryByType(TransactionType.EXPENSE);
    _hasIncomeCategories = await CategoryEntityService.existsAtLeastOneCategoryByType(TransactionType.INCOME);
    setState(() {});
  }*/

  @override
  Widget build(BuildContext context) {
    double buttonSize = (MediaQuery.of(context).size.width - 32) / 4; // 32 = 8 padding per lato * 4

    return Scaffold(
      appBar: AppBar(title: Text("Budgeting")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
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

  void _navigateToMonthlyThresholdPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MonthlyThresholdsPage()),
    ).then((_) {
      //_updateButtonFlags();
    });
  }
} 