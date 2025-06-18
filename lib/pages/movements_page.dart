import 'package:flutter/material.dart';
import 'package:myfinance2/dto/month_total_dto.dart';
import 'package:myfinance2/dto/movement_dto.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/app_config.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/utils/date_utils.dart';
import 'package:myfinance2/widgets/date_selector_panel.dart';
import 'package:myfinance2/widgets/month_totals.dart';
import 'package:myfinance2/widgets/transaction_list_grouped_by_date.dart';

class MovementsPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const MovementsPage({
    super.key, 
    required this.startDate,
    required this.endDate,
  });

  @override
  State createState() => MovementsPageState();
}

class MovementsPageState extends State<MovementsPage> {
  List<TransactionDto> _transactions = [];
  late DateTime _startDate;
  late DateTime _endDate;
  TransactionType? _selectedType;
  int? _selectedAccount;
  int? _selectedSourceAccount;
  int? _selectedCategory;
  List<Account> _accounts = [];
  List<Category> _categories = [];
  String? _currency;
  bool _multipleAccounts = false;
  MonthTotalDto _monthTotalDto = MonthTotalDto(totalExpense: 0, totalIncome: 0);

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _endDate = DateTime(MyDateUtils.getNextYear(DateTime.now().month, DateTime.now().year), MyDateUtils.getNextMonth(DateTime.now().month), 1);
    _loadTransactions();
    _loadAccountsAndCategories();
    _setCurrency();
  }

  _setCurrency() async {
    final c = await AppConfig.instance.getCurrencySymbol();
    setState(() {
      _currency = c;
    });
  }

  void _updateStartDate(DateTime newDate) {
    debugPrint("update start date $newDate");
    setState(() {
      _startDate = newDate;
    });
    _loadTransactions();
  }

  void _updateEndDate(DateTime newDate) {
    debugPrint("update end date $newDate");
    setState(() {
      _endDate = newDate;
    });
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    _transactions = await TransactionEntityService.getTransactionsWithFilters(_startDate, _endDate,
      _selectedAccount, _selectedSourceAccount, _selectedCategory, _selectedType);
    _monthTotalDto = await TransactionEntityService.getMonthTotalDtoWithFilters(_startDate, _endDate,
      _selectedAccount, _selectedSourceAccount, _selectedCategory, _selectedType);
    setState(() {});
  }
  
  Future<void> _loadAccountsAndCategories() async {
    _accounts = await AccountEntityService.getAllAccounts();
    _multipleAccounts = _accounts.length > 1;
    _categories = await CategoryEntityService.getAllExpenseAndIncomeCategories();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Movements"),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
                  _endDate = DateTime(MyDateUtils.getNextYear(DateTime.now().month, DateTime.now().year), MyDateUtils.getNextMonth(DateTime.now().month), 1);
                  _selectedType = null;
                  _selectedAccount = null;
                  _selectedSourceAccount = null;
                  _selectedCategory = null;
                  _loadTransactions();
                });
              }, 
              icon: Icon(Icons.restart_alt_rounded)
            ),
          ],
        ),
        body: SafeArea(child: _getMainBody(),
      ),
    );
  }

  Widget _getMainBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFilters(), 
          MonthTotals(
            currencySymbol: _currency ?? '', 
            totalExpense: _monthTotalDto.totalExpense, 
            totalIncome: _monthTotalDto.totalIncome,
            showMonth: false,
          ),
          _transactions.isEmpty ? Center(child: const Text("Still no movements"),) : TransactionsListGroupedByDate(transactions: _transactions, currencySymbol: _currency ?? '',)
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        children: [
          _buildDateSelectors(),
          if (_multipleAccounts) _buildAccountsDropdown("Account", _selectedAccount, (val) {
            setState(() {
              _selectedAccount = val;
              _loadTransactions();
            });
          }),
          if (_selectedType == TransactionType.TRANSFER) _buildAccountsDropdown("Source Account", _selectedSourceAccount, (val) {
            setState(() {
              _selectedSourceAccount = val;
              _loadTransactions();
            });
          }),
          if (_selectedType != TransactionType.TRANSFER)_buildCategoriesDropdown("Category", _selectedCategory, (val) {
            setState(() {
              _selectedCategory = val;
              _loadTransactions();
            });
          }),
          _buildTransactionTypeSelector(),
        ],
      ),
    );
  }

  Widget _buildDateSelectors() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSingleDateSelector("From", _startDate, (newDate) {
          _updateStartDate(newDate);
        }),
        const SizedBox(width: 20),
        _buildSingleDateSelector("To", _endDate, (newDate) {
          _updateEndDate(newDate);
        }),
      ],
    );
  }

  Widget _buildSingleDateSelector(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return DateSelectorPanel(
      label: label,
      initialDate: date,
      onChanged: onChanged,
    );
  }

  Widget _buildAccountsDropdown(String label, int? selected, ValueChanged<int?> onChanged) {
    return DropdownButton<int>(
      value: selected,
      hint: Text(label),
      onChanged: onChanged,
      items: _accounts.map((account) { 
          String accountTitle = account.icon != null ? "${account.icon!} ${account.name}" : account.name;
          return DropdownMenuItem(
            value: account.id,
            child: Text(accountTitle),
          );
        }).toList(),
    );
  }

  Widget _buildCategoriesDropdown(String label, int? selected, ValueChanged<int?> onChanged) {
    return DropdownButton<int>(
      value: selected,
      hint: Text(label),
      onChanged: onChanged,
      items: _categories.map((category) { 
          String categoryTitle = category.icon != null ? "${category.icon!} ${category.name}" : category.name;
          return DropdownMenuItem(
            value: category.id,
            child: Text(categoryTitle),
          );
        }).toList(),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: TransactionType.values.map((type) {
        if (!_multipleAccounts && type == TransactionType.TRANSFER) {
          return SizedBox();
        }
        final isSelected = _selectedType == type;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ChoiceChip(
            showCheckmark: false,
            label: Text(type.toString().split('.').last),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedType = isSelected ? null : type;
                switch (_selectedType) {
                  case null:
                    break;
                  case TransactionType.EXPENSE:
                  case TransactionType.INCOME:
                    _selectedSourceAccount = null;
                    break;
                  case TransactionType.TRANSFER:
                    _selectedCategory = null;
                    break;
                }
                _loadTransactions();
              });
            },
            selectedColor: Colors.deepPurple[300],
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }
} 