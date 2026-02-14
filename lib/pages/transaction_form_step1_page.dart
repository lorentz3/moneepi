import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/utils/color_identity.dart';
import 'package:myfinance2/utils/date_utils.dart';
import 'package:myfinance2/widgets/emoji_button.dart';
import 'package:myfinance2/widgets/section_divider.dart';

class TransactionFormStep1Page extends StatefulWidget {
  final Transaction transaction;
  final bool isNew;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final int? selectedAccount;
  final int? selectedSourceAccount;
  final int? selectedCategory;

  const TransactionFormStep1Page({
    super.key,
    required this.transaction,
    required this.isNew,
    required this.selectedDate,
    required this.selectedTime,
    this.selectedAccount,
    this.selectedSourceAccount,
    this.selectedCategory,
  });

  @override
  TransactionFormStep1PageState createState() => TransactionFormStep1PageState();
}

class TransactionFormStep1PageState extends State<TransactionFormStep1Page> {
  TransactionType _selectedType = TransactionType.EXPENSE;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedSourceAccount;
  int? _selectedAccount;
  int? _selectedCategory;
  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  final Color? _selectedButtonColor = Colors.deepPurple[200];
  final Color? _notSelectedButtonColor = Colors.grey[50];
  final bool _showTime = true;
  final bool _showDropdownMenus = false;
  final bool _showTiles = true;
  bool _multipleAccounts = false;
  bool _multipleCategories = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.transaction.type;
    _selectedDate = widget.selectedDate;
    _selectedTime = widget.selectedTime;
    _selectedAccount = widget.selectedAccount;
    _selectedSourceAccount = widget.selectedSourceAccount;
    _selectedCategory = widget.selectedCategory;
    _loadData();
  }

  Future<void> _loadData() async {
    _accounts = await AccountEntityService.getAllAccounts();
    _categories = await CategoryEntityService.getAllCategories(
      _selectedType == TransactionType.EXPENSE ? CategoryType.EXPENSE : CategoryType.INCOME
    );
    
    if (_accounts.isNotEmpty) {
      if (_accounts.length > 1) {
        _multipleAccounts = true;
      } else {
        _selectedAccount ??= _accounts[0].id;
        _selectedSourceAccount ??= _accounts[0].id;
      }
    }
    
    if (_categories.isNotEmpty) {
      if (_categories.length > 1) {
        _multipleCategories = true;
      } else {
        _selectedCategory ??= _categories[0].id;
      }
    }
    
    _isLoading = false;
    setState(() {});
    
    // Check if we can navigate to step 2
    _checkAndNavigateToStep2();
  }

  void _checkAndNavigateToStep2() {
    bool canProceed = _selectedType == TransactionType.TRANSFER
        ? _selectedAccount != null && _selectedSourceAccount != null
        : _selectedAccount != null && _selectedCategory != null;
    
    if (canProceed) {
      Navigator.pop(context, {
        'selectedDate': _selectedDate,
        'selectedTime': _selectedTime,
        'selectedAccount': _selectedAccount,
        'selectedSourceAccount': _selectedSourceAccount,
        'selectedCategory': _selectedCategory,
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedTime.hour,
          _selectedTime.minute
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScaffold();
    if (_accounts.isEmpty || _categories.isEmpty) return _buildEmptyConfigScaffold();

    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildDateTimeRow(context),
              _buildSourceAccountSelector(),
              _buildTargetAccountSelector(),
              _buildCategorySelector(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.isNew ? 'New ${getTransactionTypeText(_selectedType)}' : 'Edit ${getTransactionTypeText(_selectedType)}'),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text('Loading...')),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyConfigScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text('Configuration Required')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            SizedBox(height: 20),
            Text("You still need to configure accounts and/or categories"),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(context),
        ),
        const SizedBox(width: 12),
        _showTime ? Expanded(child: _buildTimeButton(context)) : const SizedBox(),
      ],
    );
  }

  Widget _buildDateButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _selectDate(context),
      style: _elevatedStyle(),
      child: Row(
        children: [
          Icon(Icons.calendar_month),
          const SizedBox(width: 10),
          Text(MyDateUtils.formatDate(_selectedDate) ?? "", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _selectTime(context),
      style: _elevatedStyle(),
      child: Row(
        children: [
          Icon(Icons.access_time),
          const SizedBox(width: 10),
          Text(_selectedTime.format(context), style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  ButtonStyle _elevatedStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[200],
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildSourceAccountSelector() {
    if (_selectedType != TransactionType.TRANSFER) return const SizedBox();
    return Column(
      children: [
        _showDropdownMenus
            ? _buildDropdown(
                label: 'Source account',
                value: _selectedSourceAccount,
                items: _accounts,
                onChanged: (value) {
                  setState(() => _selectedSourceAccount = value);
                  _checkAndNavigateToStep2();
                },
              )
            : SectionDivider(text: 'Source account'),
        if (_showTiles)
          _buildEmojiGrid(
            items: _accounts,
            selectedId: _selectedSourceAccount,
            onPressed: (id) {
              setState(() => _selectedSourceAccount = id);
              _checkAndNavigateToStep2();
            },
          ),
      ],
    );
  }

  Widget _buildTargetAccountSelector() {
    return Column(
      children: [
        _showDropdownMenus
            ? _buildDropdown(
                label: _selectedType == TransactionType.TRANSFER ? 'Target account' : 'Account',
                value: _selectedAccount,
                items: _accounts,
                onChanged: (value) {
                  setState(() => _selectedAccount = value);
                  _checkAndNavigateToStep2();
                },
              )
            : (_multipleAccounts ? SectionDivider(text: 'Target account') : const SizedBox()),
        if (_multipleAccounts && _showTiles)
          _buildEmojiGrid(
            items: _accounts,
            selectedId: _selectedAccount,
            onPressed: (id) {
              setState(() => _selectedAccount = id);
              _checkAndNavigateToStep2();
            },
          ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    if (_selectedType == TransactionType.TRANSFER) return const SizedBox();
    return Column(
      children: [
        _showDropdownMenus
            ? _buildDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: _categories,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  _checkAndNavigateToStep2();
                },
              )
            : (_multipleCategories ? SectionDivider(text: 'Category') : const SizedBox()),
        const SizedBox(height: 6),
        if (_multipleCategories && _showTiles)
          _buildEmojiGrid(
            items: _categories,
            selectedId: _selectedCategory,
            onPressed: (id) {
              setState(() => _selectedCategory = id);
              _checkAndNavigateToStep2();
            },
          ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required int? value,
    required List<dynamic> items,
    required Function(int?) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(labelText: label),
      value: value,
      items: items.map((item) {
        String title = item.icon != null ? "${item.icon!} ${item.name}" : item.name;
        return DropdownMenuItem<int>(
          value: item.id,
          child: Text(title),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Choose ${label.toLowerCase()}' : null,
    );
  }

  Widget _buildEmojiGrid({
    required List<dynamic> items,
    required int? selectedId,
    required Function(int) onPressed,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonSize = (screenWidth - (6 * 6) - 16 - 10) / 6;

    return Align(
      alignment: Alignment.center,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items.map<Widget>((item) {
          final String icon = item.icon ?? item.name.substring(0, 2);
          return EmojiButton(
            icon: icon,
            label: item.name,
            width: buttonSize,
            height: buttonSize,
            onPressed: () => onPressed(item.id),
            backgroundColor: selectedId == item.id ? _selectedButtonColor : _notSelectedButtonColor,
          );
        }).toList(),
      ),
    );
  }
}

String getTransactionTypeText(TransactionType type) {
  switch (type) {
    case TransactionType.EXPENSE:
      return 'Expense';
    case TransactionType.INCOME:
      return 'Income';
    case TransactionType.TRANSFER:
      return 'Transfer';
    default:
      return '';
  }
}
