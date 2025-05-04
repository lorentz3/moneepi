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
import 'package:myfinance2/pages/accounts_page.dart';
import 'package:myfinance2/pages/accounts_summaries_page.dart';
import 'package:myfinance2/pages/budgeting_page.dart';
import 'package:myfinance2/pages/categories_page.dart';
import 'package:myfinance2/pages/currency_selection_page.dart';
import 'package:myfinance2/pages/export_transactions_page.dart';
import 'package:myfinance2/pages/general_settings_page.dart';
import 'package:myfinance2/pages/groups_page.dart';
import 'package:myfinance2/pages/import_xls_page.dart';
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
  late DateTime _selectedDate;
  List<TransactionDto> transactions = [];
  List<MonthlyCategoryTransactionSummaryDto> monthCategoriesSummary = [];
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
    _loadTransactions();
    _loadSummary();
    _loadFlags();
    _loadConfigs();
  }

  _loadConfigs() async {
    _monthlySaving = await AppConfig.instance.getMonthlySaving();
    _periodStartingDay = await AppConfig.instance.getPeriodStartingDay();
    debugPrint("reloaded configs: _monthlySaving=$_monthlySaving, _periodStartingDay=$_periodStartingDay");
    setState(() {});
  }

  Future<void> _loadTransactions() async {
    transactions = await TransactionEntityService.getMonthTransactions(_selectedDate.month, _selectedDate.year);
    _monthTotalDto = await TransactionEntityService.getMonthTotalDto(_selectedDate.month, _selectedDate.year);
    setState(() {});
  }

  Future<void> _loadFlags() async {
    _accountsAreMoreThanOne = await AccountEntityService.multipleAccountExist();
    setState(() {});
  }

  Future<void> _loadSummary() async {
    debugPrint("_loadSummary");
    setState(() {
      _isSummaryLoading = true;
    });
    _groupSummaries = await GroupEntityService.getGroupWithThresholdSummaries(_selectedDate.month, _selectedDate.year);
    List<Category> categoriesWithThreshold = await CategoryEntityService.getAllCategoriesWithMonthlyThreshold(CategoryType.EXPENSE);
    monthCategoriesSummary = await MonthlyCategoryTransactionEntityService.getAllMonthCategoriesSummaries(_selectedDate.month, _selectedDate.year);
    for (Category c in categoriesWithThreshold) {
      if (!monthCategoriesSummary.any((element) => element.categoryId == c.id)) {
        monthCategoriesSummary.add(MonthlyCategoryTransactionSummaryDto(
          categoryId: c.id!, 
          categoryIcon: c.icon,
          categoryName: c.name, 
          month: _selectedDate.month, 
          year: _selectedDate.year,
          monthThreshold: c.monthThreshold));
      }
    }
    setState(() {
      _isSummaryLoading = false;
    });
  }

 void _updateDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => _navigateTo(Pages.settings),
            ),
            Divider(),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Change currency'),
              onTap: () => _navigateTo(Pages.currencies),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Accounts setup'),
              onTap: () => _navigateTo(Pages.accounts),
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Expense Categories setup'),
              onTap: () => _navigateTo(Pages.expenseCategories),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Income Categories setup'),
              onTap: () => _navigateTo(Pages.incomeCategories),
            ),
            ListTile(
              leading: const Icon(Icons.data_thresholding_outlined),
              title: const Text('Category Budgets'),
              onTap: () => _navigateTo(Pages.categoryBudgets),
            ),
            ListTile(
              leading: const Icon(Icons.group_work_outlined),
              title: const Text('Groups setup'),
              onTap: () => _navigateTo(Pages.groups),
            ),
            Divider(),
            ListTile(
              leading: const Icon(Icons.dataset_outlined),
              title: const Text('XLSX Import'),
              onTap: () => _navigateTo(Pages.xlsxImport),
            ),
            ListTile(
              leading: const Icon(Icons.dataset_rounded),
              title: const Text('XLSX Export'),
              onTap: () => _navigateTo(Pages.xlsxExport),
            ),
            Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Info'),
              onTap: () {
                Navigator.pop(context);
                // Mostra info app
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: MonthYearSelector(selectedDate: _selectedDate, onDateChanged: _updateDate),
      ),
      body: _getMainBody(),
      bottomNavigationBar: Container(
        height: 70,
        color: backgroundGrey(),
        child: Padding(
          padding: const EdgeInsets.only(top: 2, left: 6, right: 6, bottom: 14),
          child: Row(
            children: [
              FooterButton(
                text: "Income",
                onPressed: () => _navigateToTransactionPage(TransactionType.INCOME), 
                color: green()
              ),
              SizedBox(width: 6,),
              if (_accountsAreMoreThanOne) FooterButton(
                text: "Transfer", 
                onPressed: () => _navigateToTransactionPage(TransactionType.TRANSFER),
                color: blue()
              ),
              if (_accountsAreMoreThanOne) SizedBox(width: 6,),
              FooterButton(
                text: "Expense",
                onPressed: () => _navigateToTransactionPage(TransactionType.EXPENSE), 
                color: red()
              ),
            ],
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

  _getMainBody() {
    final monthString = DateFormat('MMMM').format(_selectedDate);
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
            transactions: transactions,
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
                  label: "Expenses",
                  size: 75,
                  icon: Icons.query_stats,
                  onPressed: () => _navigateToStatsPage()),
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
        children: monthCategoriesSummary
            .where((t) => t.monthThreshold != null) 
            .map((t) => ThresholdBar(
              name: t.categoryName,
              spent: t.amount ?? 0.0,
              threshold: t.monthThreshold ?? 0.0,
              icon: t.categoryIcon,
              nameColor: Colors.black, 
              currencySymbol: _currencySymbol ?? '',
              showTodayBar: _selectedDate.month == DateTime.now().month && _selectedDate.year == DateTime.now().year,
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
    case Pages.settings:
      return GeneralSettingsPage(monthlySaving: _monthlySaving ?? 0.0, periodStartingDay: _periodStartingDay ?? 1,);
  }
}
}

enum Pages {
  currencies,
  accounts,
  expenseCategories,
  incomeCategories,
  categoryBudgets,
  groups,
  xlsxImport,
  xlsxExport,
  settings,
}