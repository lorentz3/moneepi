import 'package:flutter/material.dart';
import 'package:myfinance2/dto/month_total_dto.dart';
import 'package:myfinance2/pages/monthly_threshold_page.dart';
import 'package:myfinance2/services/app_config.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/widgets/month_totals.dart';
import 'package:myfinance2/widgets/year_selector.dart';

class BudgetingPage extends StatefulWidget {
  final String currencySymbol;
  const BudgetingPage({super.key, required this.currencySymbol});

  @override
  State createState() => BudgetingPageState();
}

class BudgetingPageState extends State<BudgetingPage> {
  late String _currencySymbol;
  late DateTime _selectedDate;
  List<MonthTotalDto> _monthTotals = [];
  double? _monthlySaving;
  double _yearExpenses = 0.0;
  double _yearIncomes = 0.0;


  @override
  void initState() {
    super.initState();
    _currencySymbol = widget.currencySymbol;
    _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadStats();
  }

   Future<void> _loadStats() async {
    _monthTotals = await TransactionEntityService.getMonthTotals(_selectedDate.year);
    _yearExpenses = _monthTotals
      .map((e) => e.totalExpense)
      .fold(0.0, (prev, amount) => prev + amount);
    _yearIncomes = _monthTotals
      .map((e) => e.totalIncome)
      .fold(0.0, (prev, amount) => prev + amount);
    _monthlySaving = await AppConfig.instance.getMonthlySaving();
    setState(() {});
  }

  void _updateDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final Color groupBgColor = Colors.blueGrey.shade100;
    final Color groupBgColor2 = Colors.blueGrey.shade200;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(),
            ),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.topLeft,
                child: YearSelector(selectedDate: _selectedDate, onDateChanged: _updateDate),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: groupBgColor,
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _navigateToMonthlyThresholdPage(), 
                    child: Text("Edit Category budgets"),
                  ),
                  ElevatedButton(
                    onPressed: () {}, 
                    child: Text("Edit Monthly Saving amount"),
                  )
                ],
              ),
            ),
            Text(
              " Monthly Saving amount: $_monthlySaving",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _monthTotals.length,
              itemBuilder: (context, index) {
                MonthTotalDto monthTotal = _monthTotals[index]; //month 1 -> 12
                Color rowColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                return _getMonthTotalWidget(context, monthTotal, rowColor, index + 1);
              },
            ),
            SizedBox(height: 10,),
            Container(
              color: groupBgColor,
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
              child: Row(
                children: [ 
                  Text(
                    "  Year expenses: ",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    "${_yearExpenses.toStringAsFixed(2)} $_currencySymbol",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    " (avg: ${_monthlyAverage(_yearExpenses).toStringAsFixed(2)} $_currencySymbol) ",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            Container(
              color: groupBgColor2,
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
              child: Row(
                children: [ 
                  Text(
                    "  Year incomes: ",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    "${_yearIncomes.toStringAsFixed(2)} $_currencySymbol",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    " (avg: ${_monthlyAverage(_yearIncomes).toStringAsFixed(2)} $_currencySymbol) ",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _monthlyAverage(double total) {
    if (_selectedDate.year == DateTime.now().year) {
      return total / _selectedDate.month;
    }
    return total / 12;
  }

  Widget _getMonthTotalWidget(BuildContext context, MonthTotalDto monthTotal, Color rowColor, int month) {
    DateTime dt = DateTime(_selectedDate.year, monthTotal.month ?? 1, 1);
    double totalExpense = monthTotal.totalExpense;
    double totalIncome = monthTotal.totalIncome;
    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: MonthTotals(
        currencySymbol: _currencySymbol,
        selectedDate: dt, 
        totalExpense: totalExpense, 
        totalIncome: totalIncome,
        showMonth: true,
      ),
    );
  }

  void _navigateToMonthlyThresholdPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MonthlyThresholdsPage(currencySymbol: _currencySymbol,)),
    ).then((_) {
      //TODO _updateButtonFlags();
    });
  }
} 