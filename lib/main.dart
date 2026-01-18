import 'package:flutter/foundation.dart' as f;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/group_summary_dto.dart';
import 'package:myfinance2/dto/month_total_dto.dart';
import 'package:myfinance2/dto/monthly_category_transaction_summary_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/dto/movement_dto.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/about_page.dart';
import 'package:myfinance2/pages/accounts_page.dart';
import 'package:myfinance2/pages/accounts_summaries_page.dart';
import 'package:myfinance2/pages/budgeting_page.dart';
import 'package:myfinance2/pages/categories_page.dart';
import 'package:myfinance2/pages/currency_selection_page.dart';
import 'package:myfinance2/pages/export_transactions_page.dart';
import 'package:myfinance2/pages/period_settings_page.dart';
import 'package:myfinance2/pages/groups_page.dart';
import 'package:myfinance2/pages/import_xls_page.dart';
import 'package:myfinance2/pages/monthly_saving_settings_page.dart';
import 'package:myfinance2/pages/monthly_threshold_page.dart';
import 'package:myfinance2/pages/stats_page.dart';
import 'package:myfinance2/pages/transaction_form_page.dart';
import 'package:myfinance2/pages/movements_page.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/app_config.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/group_entity_service.dart';
import 'package:myfinance2/services/monthly_category_transaction_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:myfinance2/utils/color_identity.dart';
import 'package:myfinance2/widgets/categories_pie_chart.dart';
import 'package:myfinance2/widgets/footer_button.dart';
import 'package:myfinance2/widgets/left_to_spend.dart';
import 'package:myfinance2/widgets/month_year_selector.dart';
import 'package:myfinance2/widgets/month_totals.dart';
import 'package:myfinance2/widgets/section_divider.dart';
import 'package:myfinance2/widgets/square_button.dart';
import 'package:myfinance2/widgets/thresholds_bar.dart';
import 'package:myfinance2/widgets/transaction_list_grouped_by_date.dart';
import 'package:myfinance2/widgets/app_drawer.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

void main() {
  if (!f.kIsWeb && (f.defaultTargetPlatform == TargetPlatform.windows || f.defaultTargetPlatform == TargetPlatform.linux || f.defaultTargetPlatform == TargetPlatform.macOS)) {
    ffi.sqfliteFfiInit();
    sqflite.databaseFactory = ffi.databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneePi',
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
  late DateTime _selectedDate;
  List<TransactionDto> _transactions = [];
  List<MonthlyCategoryTransactionSummaryDto> _monthCategoriesSummary = [];
  List<MonthlyCategoryTransactionSummaryDto> _monthCategoriesSummaryBars = [];
  List<GroupSummaryDto> _groupSummaries = [];
  bool _isSummaryLoading = true;
  bool _accountsAreMoreThanOne = false;
  MonthTotalDto _monthTotalDto = MonthTotalDto(totalExpense: 0, totalIncome: 0);
  String? _currencySymbol;
  double? _monthlySaving;
  int? _periodStartingDay;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadAllData();
    _setCurrency();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ricarico solo se la schermata è tornata visibile
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _setCurrency();
    }
  }

  _setCurrency() async {
    final c = await AppConfig.instance.getCurrencySymbol();
    setState(() {
      _currencySymbol = c;
    });
  }

  _loadAllData() {
    _loadConfigs();
    _loadFlags();
  }

  _loadConfigs() async {
    _monthlySaving = await AppConfig.instance.getMonthlySaving();
    _periodStartingDay = await AppConfig.instance.getPeriodStartingDay();
    debugPrint("reloaded configs: _monthlySaving=$_monthlySaving, _periodStartingDay=$_periodStartingDay");
    await _loadTransactions();
    await _loadSummary();
    setState(() {});
  }
  
  void _updateDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      debugPrint("new _selectedDate=$_selectedDate");
    });
    _loadAllData();
  }

  Future<void> _loadTransactions() async {
    // calc start / end period
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();
    int month = _selectedDate.day < startingDay ? _selectedDate.month - 1 : _selectedDate.month;
    int year = _selectedDate.year;
    
    // Handle case where previous month is in the previous year
    if (month <= 0) {
      month = 12;
      year = _selectedDate.year - 1;
    }
    DateTime start = DateTime(year, month, startingDay);
    DateTime end = DateTime(year, month + 1, startingDay);
    debugPrint("getting Month Transactions and totals from $start to $end");
    final int startTimestamp = start.millisecondsSinceEpoch;
    final int endTimestamp = end.millisecondsSinceEpoch;

    _transactions = await TransactionEntityService.getMonthTransactions(startTimestamp, endTimestamp);
    _monthTotalDto = await TransactionEntityService.getMonthTotalDto(startTimestamp, endTimestamp);
    setState(() {});
  }

  Future<void> _loadFlags() async {
    _accountsAreMoreThanOne = await AccountEntityService.multipleAccountExist();
    setState(() {});
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isSummaryLoading = true;
    });
    // calc month / year for summaries
    final int startingDay = await AppConfig.instance.getPeriodStartingDay();
    int month = _selectedDate.day < startingDay ? _selectedDate.month - 1 : _selectedDate.month;
    int year = _selectedDate.year;
    
    // Handle case where previous month is in the previous year
    if (month <= 0) {
      month = 12;
      year = _selectedDate.year - 1;
    }
    
    _groupSummaries = await GroupEntityService.getGroupWithThresholdSummaries(month, year);
    List<Category> categoriesWithThreshold = await CategoryEntityService.getAllCategoriesWithMonthlyThreshold(CategoryType.EXPENSE);
    _monthCategoriesSummary = await MonthlyCategoryTransactionEntityService.getAllMonthCategoriesSummaries(month, year);
    for (Category c in categoriesWithThreshold) {
      if (!_monthCategoriesSummary.any((element) => element.categoryId == c.id)) {
        _monthCategoriesSummary.add(MonthlyCategoryTransactionSummaryDto(
          categoryId: c.id!, 
          categoryIcon: c.icon,
          categoryName: c.name, 
          month: month, 
          year: year,
          monthThreshold: c.monthThreshold,
          sort: c.sort
        ));
      }
    }
    _monthCategoriesSummaryBars = [..._monthCategoriesSummary];
    _monthCategoriesSummaryBars.sort((a, b) => a.sort.compareTo(b.sort));
    setState(() {
      _isSummaryLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(onNavigate: _navigateTo),
      appBar: AppBar(
        title: MonthYearSelector(
          selectedDate: _selectedDate, 
          onDateChanged: _updateDate, 
          alignment: MainAxisAlignment.start,
          periodStartingDay: _periodStartingDay,
        ),
      ),
      body: _getMainBody(),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: backgroundGrey(),
          child: Padding(
            padding: const EdgeInsets.only(top: 6, left: 6, right: 6, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: FooterButton(
                    text: "Income",
                    onPressed: () => _navigateToTransactionPage(TransactionType.INCOME), 
                    color: green()
                  ),
                ),
                SizedBox(width: 6,),
                if (_accountsAreMoreThanOne) 
                  Expanded(
                    child: FooterButton(
                      text: "Transfer", 
                      onPressed: () => _navigateToTransactionPage(TransactionType.TRANSFER),
                      color: blue()
                    ),
                  ),
                if (_accountsAreMoreThanOne) SizedBox(width: 6,),
                Expanded(
                  child: FooterButton(
                    text: "Expense",
                    onPressed: () => _navigateToTransactionPage(TransactionType.EXPENSE), 
                    color: red()
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _navigateToTransactionPage(TransactionType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TransactionFormPage(
              transaction: Transaction(
                type: type,
                timestamp: DateTime.now(),
              ),
              isNew: true,
            ),
      ),
    ).then((_) {
      _loadAllData(); 
    });
  }

  void _navigateToExpenseForCategory(int categoryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormPage(
          transaction: Transaction(
            type: TransactionType.EXPENSE,
            timestamp: DateTime.now(),
            categoryId: categoryId,
          ),
          dateTime: DateTime.now(),
          isNew: true,
        ),
      ),
    ).then((_) {
      _loadAllData();
    });
  }

  _getMainBody() {
    String monthString = DateFormat('MMMM').format(_selectedDate);
    if (_selectedDate.day < (_periodStartingDay ?? 1)) {
      DateTime tmp = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
      monthString = DateFormat('MMMM').format(tmp);
    }
    
    return SingleChildScrollView(
      child: Column (
        children: [
          _getPieChartAndButtons(),
          SizedBox(height: 5,),
          MonthTotals(
            currencySymbol: _currencySymbol ?? '', 
            selectedDate: _selectedDate, 
            totalExpense: _monthTotalDto.totalExpense, 
            totalIncome: _monthTotalDto.totalIncome,
            showMonth: false,
          ),
          if ((_monthlySaving ?? 0.0) > 0) LeftToSpendRow(
            wantToSave: _monthlySaving!, 
            currencySymbol: _currencySymbol ?? '', 
            leftToSpend: _monthTotalDto.totalIncome - _monthTotalDto.totalExpense - _monthlySaving!,
          ),
          SizedBox(height: 5,),
          _getGroupThresholdBars(),
          _getMonthThresholdBars(),
          SectionDivider(text: "$monthString transactions"),
          TransactionsListGroupedByDate(
            transactions: _transactions,
            currencySymbol: _currencySymbol ?? '',
            onTransactionUpdated: () {
              _loadAllData();
            },
          ),
          SizedBox(height: 20,),
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
            child: CategoriesPieChart(
              monthCategoriesSummary: _monthCategoriesSummary,
              pieHeight: pieHeight,
              onCategoryTap: (category) => _navigateToExpenseForCategory(category.categoryId),
            ),
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
                  label: "Expenses Stats",
                  size: 75,
                  icon: Icons.query_stats,
                  onPressed: () => _navigateToStatsPage()),
                SizedBox(height: 10),
                SquareButton(
                  label: "Accounts Summary",
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

  _getGroupThresholdBars() {
    return _isSummaryLoading
      ? SizedBox()
      : Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: _groupSummaries
            .where((groupSummary) => groupSummary.monthThreshold != null) 
            .map((groupSummary) => ThresholdBar(
              name: groupSummary.name,
              spent: groupSummary.totalExpense ?? 0.0,
              threshold: groupSummary.monthThreshold ?? 0.0,
              icon: groupSummary.icon,
              nameColor: Color.fromARGB(255, 0, 3, 136),
              currencySymbol: _currencySymbol ?? '',
              showTodayBar: _selectedDate.month == DateTime.now().month && _selectedDate.year == DateTime.now().year,
              categories: groupSummary.categories,
              periodStartingDay: _periodStartingDay,
              )
            )
            .toList(),
        ),
    );
  }

  _getMonthThresholdBars() {
    return _isSummaryLoading
      ? Center(child: CircularProgressIndicator())
      : Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: _monthCategoriesSummaryBars
            .where((t) => t.monthThreshold != null) 
            .map((t) => ThresholdBar(
              name: t.categoryName,
              spent: t.amount ?? 0.0,
              threshold: t.monthThreshold ?? 0.0,
              icon: t.categoryIcon,
              nameColor: Colors.black, 
              currencySymbol: _currencySymbol ?? '',
              showTodayBar: _selectedDate.month == DateTime.now().month && _selectedDate.year == DateTime.now().year,
              periodStartingDay: _periodStartingDay,
            ))
            .toList(),
        ),
    );
  }

  void _navigateToTransactionsPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MovementsPage(
        startDate: _selectedDate,
        endDate: DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day),
      )),
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
      MaterialPageRoute(builder: (context) => BudgetingPage(currencySymbol: _currencySymbol ?? '',)),
    ).then((_) {
      _loadAllData(); // TODO only if something changed
    });
  }
  
  _navigateToStatsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StatsPage(currencySymbol: _currencySymbol ?? '',)),
    );
  }

  void _navigateTo(Pages page) async {
    Navigator.pop(context); // closes the drawer
    final bool? dataChanged = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _getPage(page)),
    );
    if (dataChanged != null && dataChanged) {
      debugPrint("Data changed! Reload data");
      _loadAllData();
      _setCurrency();
    }
  }

_getPage(Pages page) {
  switch(page) {
    case Pages.accounts:
      return AccountsPage();
    case Pages.currencies:
      return CurrencySelectionPage();
    case Pages.expenseCategories:
      return CategoriesPage(type: CategoryType.EXPENSE,);
    case Pages.incomeCategories:
      return CategoriesPage(type: CategoryType.INCOME,);
    case Pages.categoryBudgets:
      return MonthlyThresholdsPage(currencySymbol: _currencySymbol ?? '');
    case Pages.groups:
      return GroupListPage(currencySymbol: _currencySymbol ?? '');
    case Pages.xlsxImport:
      return ImportXlsPage();
    case Pages.xlsxExport:
      return ExportTransactionsPage();
    case Pages.monthlySavingsSettings:
      return MonthlySavingSettingsPage(monthlySaving: _monthlySaving ?? 0.0);
    case Pages.periodSettings:
      return PeriodSettingsPage(periodStartingDay: _periodStartingDay ?? 1,);
    case Pages.about:
      return AboutPage();
  }
}
}
