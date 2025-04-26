import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/category_summary_dto.dart';
import 'package:myfinance2/dto/group_dto.dart';
import 'package:myfinance2/dto/group_stats_dto.dart';
import 'package:myfinance2/dto/month_total_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/group.dart';
import 'package:myfinance2/pages/general_settings_page.dart';
import 'package:myfinance2/pages/monthly_threshold_page.dart';
import 'package:myfinance2/services/app_config.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/group_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/utils/color_identity.dart';
import 'package:myfinance2/widgets/icon_text_button.dart';
import 'package:myfinance2/widgets/month_totals_row.dart';
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
  int ? _periodStartingDay;
  double _yearExpenses = 0.0;
  double _yearIncomes = 0.0;
  int _effectiveMonths = 1;
  bool _dataChanged = false;
  List<GroupDto> _groups = [];
  List<Category> _categories = [];
  bool _groupExists = false;
  double _totalPlannedBudget = 0.0;

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
    _periodStartingDay = await AppConfig.instance.getPeriodStartingDay();
    _countEffectiveMonths();
    _groups = await GroupEntityService.getGroupsWithMonthlyThreshold();
    _groupExists = _groups.isNotEmpty;
    _totalPlannedBudget = 0.0;
    if (_groupExists) {
      _totalPlannedBudget += _groups.map((e) => e.monthThreshold).fold(0, (prev, amount) => prev + (amount ?? 0.0));
    }
    _categories = await CategoryEntityService.getCategoriesWithMonthlyThresholdNotInGroups(CategoryType.EXPENSE, _groups);  
    if (_categories.isNotEmpty) {
      _totalPlannedBudget += _categories.map((e) => e.monthThreshold).fold(0, (prev, amount) => prev + (amount ?? 0.0));
    }
    _totalPlannedBudget += _monthlySaving ?? 0.0;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          debugPrint("Popping BudgetingPage _dataChanged=$_dataChanged, result=$result");
          Navigator.pop(context, _dataChanged);
        }
      },
      child: Scaffold(
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
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                child: Row(
                  children: [
                    IconTextButton(
                      onPressed: () => _navigateToMonthlyThresholdPage(),
                      text: "Edit Category budgets",
                      textColor: deepPurple(),
                      backgroundColor: Colors.deepPurple[50],
                      borderColor: Colors.deepPurple[300],
                    ),
                    Expanded(child: SizedBox(width: 20,)),
                    IconTextButton(
                      onPressed: () => _navigateToSettingsPage(), 
                      text: "Edit Monthly Saving",
                      textColor: deepPurple(),
                      backgroundColor: Colors.deepPurple[50],
                      borderColor: Colors.deepPurple[300],
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 15),
                child: Text(
                  "Categories with planned budget:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ..._groups.map((group) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header con gruppo
                    Container(
                      color: groupBgColor,
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                      child: Row(
                        children: [
                          Text(
                            "${group.icon ?? ""} ${group.name}",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: SizedBox(width: 1,)),
                          Text(
                            "${(group.monthThreshold ?? 0.0).toStringAsFixed(2)} $_currencySymbol",
                            style: TextStyle(fontSize: 16,),
                          ),
                          SizedBox(width: 10,)
                        ],
                      ),
                    ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: group.categories.length,
                      itemBuilder: (context, index) {
                        Category category = group.categories[index];
                        Color rowColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                        return _getCategoryWidget(context, category, rowColor, false);
                      },
                    ),
                  ],
                );
              }),
              // Lista senza raggruppamenti
            if (_categories.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_groupExists) Container(
                    color: groupBgColor,
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                    child: Row(
                      children: [ 
                        Text(
                          "Other categories",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      Category category = _categories[index];
                      Color rowColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                      return _getCategoryWidget(context, category, rowColor, true);
                    },
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 15),
                child: Text(
                  "Monthly Saving amount: ${(_monthlySaving ?? 0.0).toStringAsFixed(2)} $_currencySymbol",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 15),
                child: Text(
                  "Total budget per month: ${(_totalPlannedBudget).toStringAsFixed(2)} $_currencySymbol",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              MonthTotalsRow(
                firstCellLabel: "Mon",
                incomeColumn: "Incomes ($_currencySymbol)",
                expenseColumn: "Expenses ($_currencySymbol)",
                savedColumn: "Saved ($_currencySymbol)",
                backgroundColor: groupBgColor2,
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
              MonthTotalsRow(
                firstCellLabel: "Tot",
                incomeColumn: _yearIncomes.toStringAsFixed(2),
                expenseColumn: _yearExpenses.toStringAsFixed(2),
                savedColumn: (_yearIncomes - _yearExpenses).toStringAsFixed(2),
                backgroundColor: groupBgColor,
              ),
              MonthTotalsRow(
                firstCellLabel: "Avg",
                incomeColumn: (_yearIncomes / _effectiveMonths).toStringAsFixed(2),
                expenseColumn: (_yearExpenses / _effectiveMonths).toStringAsFixed(2),
                savedColumn: ((_yearIncomes - _yearExpenses) / _effectiveMonths).toStringAsFixed(2),
                backgroundColor: groupBgColor2,
                savedColumnColor: ((_yearIncomes - _yearExpenses) / _effectiveMonths) - (_monthlySaving ?? 0.0) > 0 ? green() : red(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getMonthTotalWidget(BuildContext context, MonthTotalDto monthTotal, Color rowColor, int month) {
    DateTime dt = DateTime(_selectedDate.year, monthTotal.month ?? 1, 1);
    double totalExpense = monthTotal.totalExpense;
    double totalIncome = monthTotal.totalIncome;
    double balance = totalIncome - totalExpense;
    return MonthTotalsRow(
      firstCellLabel: DateFormat("MMM").format(dt), 
      expenseColumn: totalExpense.toStringAsFixed(2),
      expenseColumnColor: red(),
      incomeColumn: totalIncome.toStringAsFixed(2),
      incomeColumnColor: green(),
      savedColumn: balance.toStringAsFixed(2),
      savedColumnColor: balance >= 0 ? ((_monthlySaving ?? 0.0) >= 0 && (balance - (_monthlySaving ?? 0.0)) >= 0) ? blue() : magenta() : red(),
      backgroundColor: rowColor,
    );
  }

  void _navigateToMonthlyThresholdPage() async {
    _dataChanged = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MonthlyThresholdsPage(currencySymbol: _currencySymbol,)),
    );
    if (_dataChanged) {
      setState(() {
        _loadStats();
      });
    }
  }

  void _navigateToSettingsPage() async {
    _dataChanged = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GeneralSettingsPage(
        monthlySaving: _monthlySaving ?? 0.0,
        periodStartingDay: _periodStartingDay ?? 1,
      )),
    );
    if (_dataChanged) {
      setState(() {
        _loadStats();
      });
    }
  }
  
  void _countEffectiveMonths() {
    _effectiveMonths = 0;
    for (MonthTotalDto m in _monthTotals) {
      if (m.totalExpense > 0 || m.totalIncome > 0) {
        _effectiveMonths++;
      }
    }
    if (_effectiveMonths == 0) {
      _effectiveMonths = 1;
    }
  }

  Widget _getCategoryWidget(BuildContext context, Category category, Color rowColor, bool showThreshold) {
    String categoryTitle = "${category.icon ?? ""} ${category.name}";
    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        children: [
          Text(
            "   $categoryTitle",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Expanded(child: SizedBox(width: 1,)),
          showThreshold ? Text(
            "${(category.monthThreshold ?? 0.0).toStringAsFixed(2)} $_currencySymbol",
            style: TextStyle(fontSize: 16,),
          ) : SizedBox(width: 1,),
          SizedBox(width: 10,)
        ],
      ),
    );
  }
} 