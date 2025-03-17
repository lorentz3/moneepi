import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/monthly_category_transaction_summary_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/dto/movement_dto.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/accounts_summaries_page.dart';
import 'package:myfinance2/pages/budgeting_page.dart';
import 'package:myfinance2/pages/settings_page.dart';
import 'package:myfinance2/pages/transaction_form_page.dart';
import 'package:myfinance2/pages/movements_page.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/monthly_category_transaction_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:myfinance2/widgets/categories_pie_chart.dart';
import 'package:myfinance2/widgets/month_selector.dart';
import 'package:myfinance2/widgets/monthly_thresholds_bar.dart';
import 'package:myfinance2/widgets/section_divider.dart';
import 'package:myfinance2/widgets/square_button.dart';
import 'package:myfinance2/widgets/transaction_list_grouped_by_date.dart';

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
      localizationsDelegates: [
        MonthYearPickerLocalizations.delegate,
      ],
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
  late DateTime selectedDate;
  List<TransactionDto> transactions = [];
  List<MonthlyCategoryTransactionSummaryDto> monthCategoriesSummary = [];
  bool _isSummaryLoading = true;
  bool _isCurrentMonth = true;
  final bool _firstDaysOfMonth = DateTime.now().day < 7;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadAllData();
  }

  _loadAllData() {
    _isCurrentMonth = selectedDate.month == DateTime.now().month;
    _loadTransactions();
    _loadSummary();
  }

  Future<void> _loadTransactions() async {
    if (_isCurrentMonth && _firstDaysOfMonth) {
      transactions = await TransactionEntityService.getLastDaysTransactions(7);
    } else {
      transactions = await TransactionEntityService.getMonthTransactions(selectedDate.month, selectedDate.year);
    }
    setState(() {});
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isSummaryLoading = true;
    });
    List<Category> categoriesWithThreshold = await CategoryEntityService.getAllCategoriesWithMonthlyThreshold(CategoryType.EXPENSE);
    monthCategoriesSummary = await MonthlyCategoryTransactionEntityService.getAllMonthCategoriesSummaries(selectedDate.month, selectedDate.year);
    for (Category c in categoriesWithThreshold) {
      if (!monthCategoriesSummary.any((element) => element.categoryId == c.id)) {
        monthCategoriesSummary.add(MonthlyCategoryTransactionSummaryDto(
          categoryId: c.id!, 
          categoryIcon: c.icon,
          categoryName: c.name, 
          month: selectedDate.month, 
          year: selectedDate.year,
          monthThreshold: c.monthThreshold));
      }
    }
    setState(() {
      _isSummaryLoading = false;
    });
  }

 void _updateDate(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
    });
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MonthSelector(selectedDate: selectedDate, onDateChanged: _updateDate),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              ).then((_) {
                _loadAllData(); 
              });
            },
          ),
        ],
      ),
      body: _getMainBody(),
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
            _loadAllData(); 
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }


  _getMainBody() {
    final monthString = DateFormat('MMMM').format(selectedDate);
    return SingleChildScrollView(
      child: Column (
        children: [
          _getPieChartAndButtons(),
          _getMonthThresholdBars(),
          SectionDivider(text: _isCurrentMonth && _firstDaysOfMonth ? "Last 7 days transactions" : "$monthString transactions"),
          TransactionsListGroupedByDate(
            transactions: transactions,
            onTransactionUpdated: () {
              _loadAllData();
            },
          ),
        ],
      ),
    );
  }

  _getPieChartAndButtons() { 
    double pieHeight = 180;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: pieHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SquareButton(
                  label: "Movements",
                  size: 75,
                  icon: Icons.compare_arrows,
                  onPressed: () => _navigateToTransactionsPage(context)),
                SizedBox(height: 10),
                SquareButton(
                  label: "Budgeting",
                  size: 75,
                  icon: Icons.monetization_on_outlined,
                  onPressed: () => _navigateToBudgetingPage()),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CategoriesPieChart(monthCategoriesSummary: monthCategoriesSummary, pieHeight: pieHeight,),
          ),
        ),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: pieHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SquareButton(
                  label: "Stats",
                  size: 75,
                  icon: Icons.query_stats,
                  highlight: true,
                  highlightText: "Coming soon",
                  onPressed: () {/*TODO*/}),
                SizedBox(height: 10),
                SquareButton(
                  label: "Accounts",
                  size: 75, 
                  icon: Icons.account_balance_wallet_outlined, 
                  onPressed: () => _navigateToAccountsSummariesPage()),
              ],
            ),
          ),
        ),
      ]
    );
  }

  _getMonthThresholdBars() {
    return _isSummaryLoading
      ? Center(child: CircularProgressIndicator())
      : Padding(
      padding: EdgeInsets.all(5),
      child: Column(
        children: monthCategoriesSummary
            .where((t) => t.monthThreshold != null) 
            .map((t) => MonthlyThresholdsBar(summary: t))
            .toList(),
        ),
    );
  }

  void _navigateToTransactionsPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MovementsPage(dateTime: selectedDate,)),
    ).then((_) {
      _loadAllData(); // TODO only if something changed
    });
  }

  void _navigateToAccountsSummariesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AccountSummaryPage()),
    );
  }
  
  _navigateToBudgetingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BudgetingPage()),
    ).then((_) {
      _loadAllData(); // TODO only if something changed
    });
  }
}
