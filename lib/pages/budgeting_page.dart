import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/group_dto.dart';
import 'package:myfinance2/dto/month_total_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/pages/monthly_saving_settings_page.dart';
import 'package:myfinance2/pages/monthly_threshold_page.dart';
import 'package:myfinance2/services/app_config.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/clean_service.dart';
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
    await CleanService.cleanTablesFromDeletedObjects();
    _monthTotals = await TransactionEntityService.getMonthTotals(_selectedDate.year);
    _yearExpenses = _monthTotals
      .map((e) => e.totalExpense)
      .fold(0.0, (prev, amount) => prev + amount);
    _yearIncomes = _monthTotals
      .map((e) => e.totalIncome)
      .fold(0.0, (prev, amount) => prev + amount);
    _monthlySaving = await AppConfig.instance.getMonthlySaving();
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

    List<Widget> listItems = [];
    bool isEven = true; // Per alternare i colori

    // Aggiungo i gruppi
    for (var group in _groups) {
      Color rowColor = isEven ? Colors.white : Colors.grey[200]!;
      listItems.add(
        Container(
          color: rowColor,
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          child: Row(
            children: [
              Text(
                "${group.icon ?? ""} ${group.name}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(child: SizedBox(width: 1)),
              Text(
                "${(group.monthThreshold ?? 0.0).toStringAsFixed(2)} $_currencySymbol",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(width: 10),
            ],
          ),
        ),
      );
      isEven = !isEven; // Alterno il colore
    }

    // Aggiungo le categorie senza gruppo
    for (var category in _categories) {
      Color rowColor = isEven ? Colors.white : Colors.grey[200]!;
      listItems.add(
        _getCategoryWidget(context, category, rowColor, true),
      );
      isEven = !isEven; // Alterno il colore
    }

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
          body: SafeArea(child: SingleChildScrollView(
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
                  color: groupBgColor,
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  child: Text(
                    "Categories with planned budget:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    return listItems[index];
                  },
                ),
                Container(
                  color: groupBgColor2,
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  child: Row(
                    children: [
                      Text(
                        "Monthly Saving amount:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ), 
                      Expanded(child: SizedBox(width: 1,)),
                      Text(
                        "${(_monthlySaving ?? 0.0).toStringAsFixed(2)} $_currencySymbol",
                        style: TextStyle(
                          color: blue(),
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                      ), 
                      SizedBox(width: 10,)
                    ],
                  ),
                ),
                Container(
                  color: groupBgColor,
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  child: Row(
                    children: [
                      Text(
                        "Total budget per month:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: SizedBox(width: 1,)),
                      Text(
                        "${(_totalPlannedBudget).toStringAsFixed(2)} $_currencySymbol",
                        style: TextStyle(
                          color: deepPurple(),
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                      ), 
                      SizedBox(width: 10,)
                    ],
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
                SizedBox(height: 30,)
              ],
            ),
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
      MaterialPageRoute(builder: (context) => MonthlySavingSettingsPage(
        monthlySaving: _monthlySaving ?? 0.0,
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
            categoryTitle,
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