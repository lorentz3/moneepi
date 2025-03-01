import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/monthly_category_transaction_summary_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/dto/transaction_dto.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/accounts_page.dart';
import 'package:myfinance2/pages/categories_page.dart';
import 'package:myfinance2/pages/transaction_form_page.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/monthly_category_transaction_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:myfinance2/widgets/categories_pie_chart.dart';
import 'package:myfinance2/widgets/monthly_thresholds_bar.dart';
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

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadAllData();
  }

  _loadAllData() {
    _loadTransactions();
    _loadSummary();
  }

  Future<void> _loadTransactions() async {
    transactions = await TransactionEntityService.getMonthTransactions(
      selectedDate.month,
    );
    setState(() {});
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isSummaryLoading = true;
    });
    List<Category> categoriesWithThreshold = await CategoryEntityService.getAllCategoriesWithMonthlyThreshold(TransactionType.EXPENSE);
    monthCategoriesSummary = await MonthlyCategoryTransactionEntityService.getAllMonthCategoriesSummaries(selectedDate.month, selectedDate.year);
    for (Category c in categoriesWithThreshold) {
      if (!monthCategoriesSummary.any((element) => element.categoryId == c.id)) {
        monthCategoriesSummary.add(MonthlyCategoryTransactionSummaryDto(
          categoryId: c.id!, 
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

  void _changeMonth(int delta) {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + delta, 1);
    });
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _getMonthSelectorWidget(),
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

  _handleClick(String value, BuildContext context) async {
    switch (value) {
      case "Accounts":
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountsPage()),
        ).then((_) => setState(() {
            _loadAllData();
          })
        );
        break;
      case "ExpenseCategories":
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    const CategoriesPage(type: TransactionType.EXPENSE),
          ),
        ).then((_) => setState(() {
            _loadAllData();
          })
        );
        break;
      case "IncomeCategories":
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    const CategoriesPage(type: TransactionType.INCOME),
          ),
        ).then((_) => setState(() {
            _loadAllData();
          })
        );
        break;
    }
  }

  _getMainBody() {
    return SingleChildScrollView(
      child: Column (
        children: [
          _getPieChartAndButtons(),
          _getMonthThresholdBars(),
          SizedBox(height: 5,),
          TransactionsListGroupedByDate(transactions: transactions),
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
                _buildSquareButton("Settings", Icons.settings),
                SizedBox(height: 10),
                _buildSquareButton("Movements", Icons.compare_arrows),
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
                _buildSquareButton("Stats", Icons.query_stats),
                SizedBox(height: 10),
                _buildSquareButton("Budget", Icons.monetization_on_outlined),
              ],
            ),
          ),
        ),
      ]
    );
  }

Widget _buildSquareButton(String label, IconData icon) {
  return SizedBox(
    width: 70,
    height: 70,
    child: ElevatedButton(
      onPressed: () {}, // TODO
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.deepPurple[100],
        padding: EdgeInsets.symmetric(vertical: 4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.black54),
          SizedBox(height: 3), 
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
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
  
  _getMonthSelectorWidget() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          GestureDetector(
            onTap: _pickMonthYear,
            child: Text(
              DateFormat(' MMM yyyy ').format(selectedDate),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonthYear() async {
    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2200),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      selectedDate = DateTime(picked.year, picked.month, 1);
    });
    _loadAllData();
  }
}
