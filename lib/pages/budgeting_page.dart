import 'package:flutter/material.dart';
import 'package:myfinance2/pages/groups_page.dart';
import 'package:myfinance2/pages/monthly_threshold_page.dart';
import 'package:myfinance2/widgets/square_button.dart';

class BudgetingPage extends StatefulWidget {
  final String currencySymbol;
  const BudgetingPage({super.key, required this.currencySymbol});

  @override
  State createState() => BudgetingPageState();
}

class BudgetingPageState extends State<BudgetingPage> {
  late String _currencySymbol;

  @override
  void initState() {
    super.initState();
    _currencySymbol = widget.currencySymbol;
  }

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
              label: "Monthly Budgets",
              icon: Icons.data_thresholding_outlined,
              size: buttonSize,
              highlight: false,
              highlightText: "",
              onPressed: () => _navigateToMonthlyThresholdPage(context),
            ),
            SquareButton(
              label: "Category Groups",
              icon: Icons.group_work_outlined,
              size: buttonSize,
              onPressed: () => _navigateToGroupListPage(),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMonthlyThresholdPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MonthlyThresholdsPage(currencySymbol: _currencySymbol,)),
    ).then((_) {
      //_updateButtonFlags();
    });
  }
  
  void _navigateToGroupListPage() async{
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupListPage(currencySymbol: _currencySymbol,)),
    );
  }
} 