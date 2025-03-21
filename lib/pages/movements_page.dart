import 'package:flutter/material.dart';
import 'package:myfinance2/dto/movement_dto.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/widgets/month_selector.dart';
import 'package:myfinance2/widgets/transaction_list_grouped_by_date.dart';

class MovementsPage extends StatefulWidget {
  final DateTime dateTime;
  const MovementsPage({super.key, required this.dateTime});

  @override
  State createState() => MovementsPageState();
}

class MovementsPageState extends State<MovementsPage> {
  late DateTime _selectedDate = widget.dateTime;
  List<TransactionDto> transactions = [];
  DateTime? _startDate;
  DateTime? _endDate;
  TransactionType? _selectedType;
  int? _selectedAccount;
  int? _selectedSourceAccount;
  int? _selectedCategory;
  List<Account> _accounts = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadAccountsAndCategories();
  }

  void _updateDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    transactions = await TransactionEntityService.getMonthTransactionsWithFilters(_selectedDate.month, _selectedDate.year,
      _selectedAccount, _selectedSourceAccount, _selectedCategory, _selectedType);
    setState(() {});
  }
  
  Future<void> _loadAccountsAndCategories() async {
    _accounts = await AccountEntityService.getAllAccounts();
    _categories = await CategoryEntityService.getAllExpenseAndIncomeCategories();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: MonthSelector(selectedDate: _selectedDate, onDateChanged: _updateDate),),
      body: _getMainBody(),
    );
  }

  Widget _getMainBody() {
    return SingleChildScrollView(
        child: Column(
          children: [
            _buildFilters(), 
            transactions.isEmpty ? Center(child: const Text("Still no movements"),) : TransactionsListGroupedByDate(transactions: transactions)
          ],
        ),
      );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        children: [
          _buildAccountsDropdown("Account", _selectedAccount, (val) {
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
          ElevatedButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _selectedType = null;
                _selectedAccount = null;
                _selectedSourceAccount = null;
                _selectedCategory = null;
                _loadTransactions();
              });
            },
            child: Text("Reset"),
          ),
        ],
      ),
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
    return SegmentedButton<TransactionType>(
      emptySelectionAllowed: true,
      segments: TransactionType.values
          .map((type) => ButtonSegment<TransactionType>(
                value: type,
                label: Text(type.toString().split('.').last),
              ))
          .toList(),
      selected: _selectedType != null ? {_selectedType!} : {},
      onSelectionChanged: (newSelection) {
        setState(() {
          _selectedType = newSelection.isNotEmpty ? newSelection.first : null;
          switch (_selectedType) {
            case null:
              break;
            case TransactionType.EXPENSE:
              _selectedSourceAccount = null;
            case TransactionType.INCOME:
              _selectedSourceAccount = null;
            case TransactionType.TRANSFER:
              _selectedCategory = null;
          }
          _loadTransactions();
        });
      },
    );
  }
  //MonthSelector(selectedDate: _selectedDate, onDateChanged: _updateDate)
} 