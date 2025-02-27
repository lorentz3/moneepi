import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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
  bool isTransactionListLoading = true;
  bool isSummaryLoading = true;
  bool _monthThresholdsVisible = false;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadAllData();
  }

  _loadAllData() {
    debugPrint("loadAllData");
    _loadSummary();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      debugPrint("setState isTransactionListLoading true");
      isTransactionListLoading = true;
    });
    transactions = await TransactionEntityService.getMonthTransactions(
      selectedDate.month,
    );
    setState(() {
      debugPrint("setState isTransactionListLoading false");
      isTransactionListLoading = false;
    });
  }

  Future<void> _loadSummary() async {
    setState(() {
      debugPrint("setState isSummaryLoading true");
      isSummaryLoading = true;
    });
    List<Category> categoriesWithThreshold = await CategoryEntityService.getAllCategoriesWithMonthlyThreshold(TransactionType.EXPENSE);
    monthCategoriesSummary = await MonthlyCategoryTransactionEntityService.getAllMonthCategoriesSummaries(selectedDate.month, selectedDate.year);
    _monthThresholdsVisible = monthCategoriesSummary.any((element) => element.monthThreshold != null);
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
    await Future.delayed(Duration(seconds: 3));
    setState(() {
      debugPrint("setState isSummaryLoading false");
      isSummaryLoading = false;
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
    //double width = 300;
    //if (mounted) width = MediaQuery.of(context).size.width;
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
            debugPrint("Tornato alla prima pagina!");
            _loadAllData();
            setState(() {}); 
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
    return Column (
      children: [
        _getSummaryGraphWidget(),
        Expanded(child: _getTransactionsWidget()),
      ],
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

  final double _pieHeight = 180;

  _getSummaryGraphWidget() {
    return isSummaryLoading 
      ? Center(child: CircularProgressIndicator()) : 
      monthCategoriesSummary.isEmpty ? const SizedBox(height: 10,) : 
      Padding(
        padding: EdgeInsets.all(4),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: _pieHeight,
                    child: PieChart(
                      PieChartData(
                        sections: _generatePieSections(monthCategoriesSummary),
                        centerSpaceRadius: 0,
                        sectionsSpace: 1,
                        startDegreeOffset: -90
                      ),
                    ),
                  ),
                ),
                _monthThresholdsVisible ? Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: _pieHeight, 
                    child: SingleChildScrollView(
                      child: Column(
                        children: monthCategoriesSummary
                            .where((t) => t.monthThreshold != null) 
                            .map((t) => _buildProgressIndicator(t))
                            .toList(),
                      ),
                    ),
                  ),
                ) : SizedBox(width: 1,),
              ],
            ),
          ],
        ),
      );
  }

  List<PieChartSectionData> _generatePieSections(List<MonthlyCategoryTransactionSummaryDto> monthCategoriesSummary) {
    final totalAmount = monthCategoriesSummary.fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));

    return monthCategoriesSummary.asMap().entries.map((entry) {
      var index = entry.key;
      var e = entry.value;
      final percentage = ((e.amount ?? 0.0) / totalAmount) * 100;
      return PieChartSectionData(
        color: _getColor(index), // Colori dinamici
        value: e.amount,
        title: percentage > 3 ? e.categoryName.split(" ")[0] : '',
        titlePositionPercentageOffset: 0.85,
        radius: 85,
        titleStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Color _getColor(int index) {
    final colors = [Colors.blue[900], Colors.purple[900], Colors.green[900], Colors.brown[700], Colors.red[900],
      Colors.orange[900], Colors.yellow[900], Colors.lime[900], Colors.pink[900],
      Colors.cyan[900], Colors.indigo[900], Colors.teal[900],];
      return colors[index % colors.length]!;
  }

  Widget _buildProgressIndicator(MonthlyCategoryTransactionSummaryDto summary) {
    double spent = summary.amount ?? 0.0;
    double threshold = summary.monthThreshold ?? 0.0;
    double percentage = 100 * ((threshold > 0) ? (spent / threshold).clamp(0.0, 1.5) : 0.0);
    Color progressColor = percentage > 80 ? (percentage > 100 ? Colors.red[300]! : Colors.orange[200]!) : Colors.green[300]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: percentage.toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  flex: (100 - percentage).toInt(),
                  child: SizedBox(),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      summary.categoryName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Text(
                    '${(percentage).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _getTransactionsWidget() {
    final groupedTransactions = _groupTransactionsByDate();
    Color groupBgColor = Colors.blueGrey.shade100;
    return isTransactionListLoading
      ? Center(child: CircularProgressIndicator())
      : transactions.isEmpty
      ? Center(
        child: Text(
          'Still no transactions for this month!',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      )
      : ListView(
        children: groupedTransactions.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: groupBgColor,
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                child: Row(
                  children: [
                    Text(
                      DateFormat('EEE ').format(DateTime.parse(entry.key)),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple),
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
                      Expanded(
                        flex: 15, 
                        child: Text(
                          transaction.categoryName, 
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Expanded(
                        flex: 10, 
                        child: Text(
                          transaction.type == TransactionType.EXPENSE
                              ? ' - € ${transaction.amount.toStringAsFixed(2)} '
                              : ' + € ${transaction.amount.toStringAsFixed(2)} ',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: transaction.type == TransactionType.EXPENSE ? const Color.fromARGB(255, 206, 35, 23) : const Color.fromARGB(255, 33, 122, 34),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3, 
                        child: Text(
                          transaction.accountName.split(" ")[0], 
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        )
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }).toList(),
      );
  }
}
