import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/utils/date_utils.dart';
import 'package:myfinance2/widgets/amount_input_field.dart';
import 'package:myfinance2/widgets/emoji_button.dart';
import 'package:myfinance2/widgets/section_divider.dart';

class TransactionFormPage extends StatefulWidget {
  final int? transactionId;
  final Transaction? transaction;
  final bool isNew;
  final DateTime? dateTime;

  const TransactionFormPage({super.key, this.transactionId, this.transaction, required this.isNew, this.dateTime});

  @override
  TransactionFormPageState createState() => TransactionFormPageState();
}

class TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  TransactionType _selectedType = TransactionType.EXPENSE;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedSourceAccount;
  int? _selectedAccount;
  int? _selectedCategory;
  double _amount = 0.0;
  String? _notes = '';
  List<Account> _accounts = [];
  List<Category> _categories = [];
  Transaction _transaction = Transaction(type: TransactionType.EXPENSE, timestamp: DateTime.now());
  int? _transactionId;
  bool _isNew = false;
  int? _oldCategoryId;
  int? _oldAccountId;
  DateTime? _oldTimestamp;
  int? _oldSourceAccountId;
  bool _isLoading = true;
  final Color? _selectedButtonColor = Colors.deepPurple[200]; // Selected
  final Color? _notSelectedButtonColor = Colors.grey[50];
  bool _showTime = true; // TODO config
  bool _showDropdownMenus = false; // TODO config
  bool _showTiles = true; // TODO config
  bool _multipleAccounts = false;
  bool _multipleCategories = false;

  @override
  void initState() {
    super.initState();
    _isNew = widget.isNew;
    if (_isNew) {
      _transaction = widget.transaction!;
      _selectedDate = widget.dateTime ?? DateTime.now();
      _selectedType = widget.transaction!.type;
    } else {
      _transactionId = widget.transactionId!;
      _loadTransaction();
    }
    _loadData();
  }

  _loadTransaction() async {  
    _transaction = await TransactionEntityService.getById(_transactionId);
    _selectedType = _transaction.type;
    _selectedDate = _transaction.timestamp;
    _selectedTime = TimeOfDay.fromDateTime(_transaction.timestamp);
    _selectedAccount = _transaction.accountId;
    _selectedSourceAccount = _transaction.sourceAccountId;
    _selectedCategory = _transaction.categoryId;
    _amount = _transaction.amount ?? 0.0;
    _notes = _transaction.notes;
    _oldCategoryId = _transaction.categoryId;
    _oldAccountId = _transaction.accountId;
    _oldTimestamp = _transaction.timestamp;
    _oldSourceAccountId = _transaction.sourceAccountId;
  }

  Future<void> _loadData() async {
    _accounts = await AccountEntityService.getAllAccounts();
    _categories = await CategoryEntityService.getAllCategories(_selectedType == TransactionType.EXPENSE ? CategoryType.EXPENSE : CategoryType.INCOME);
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
    setState(() { });
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
        _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, _selectedTime.hour, _selectedTime.minute);
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
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScaffold();
    if (_accounts.isEmpty || _categories.isEmpty) return _buildEmptyConfigScaffold();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque, // molto importante per rilevare i tap ovunque
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDateTimeRow(context),
                  _buildSourceAccountSelector(),
                  _buildTargetAccountSelector(),
                  _buildCategorySelector(),
                  SizedBox(height: 20),
                  _buildAmountField(),
                  _buildNotesField(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildSaveButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isNew ? 'New ${getTransactionTypeText(_selectedType)}' : 'Edit ${getTransactionTypeText(_selectedType)}'),
      actions: [
        if (!_isNew)
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmationDialog(context),
          ),
      ],
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New ${getTransactionTypeText(_selectedType)}' : 'Edit ${getTransactionTypeText(_selectedType)}')),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyConfigScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New ${getTransactionTypeText(_selectedType)}' : 'Edit ${getTransactionTypeText(_selectedType)}')),
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
          Text(MyDateUtils.formatDate(_selectedDate), style: TextStyle(fontSize: 16)),
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
                onChanged: (value) => setState(() => _selectedSourceAccount = value),
              )
            : SectionDivider(text: 'Source account'),
        if (_showTiles)
          _buildEmojiGrid(
            items: _accounts,
            selectedId: _selectedSourceAccount,
            onPressed: (id) => setState(() => _selectedSourceAccount = id),
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
                onChanged: (value) => setState(() => _selectedAccount = value),
              )
            : (_multipleAccounts ? SectionDivider(text: 'Target account') : const SizedBox()),
        if (_multipleAccounts && _showTiles)
          _buildEmojiGrid(
            items: _accounts,
            selectedId: _selectedAccount,
            onPressed: (id) => setState(() => _selectedAccount = id),
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
                onChanged: (value) => setState(() => _selectedCategory = value),
              )
            : (_multipleCategories ? SectionDivider(text: 'Category') : const SizedBox()),
        const SizedBox(height: 6),
        if (_multipleCategories && _showTiles)
          _buildEmojiGrid(
            items: _categories,
            selectedId: _selectedCategory,
            onPressed: (id) => setState(() => _selectedCategory = id),
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

  Widget _buildAmountField() {
    return AmountInputField(
      initialAmount: _amount,
      label: "Amount",
      onChanged: (val) {
        setState(() {
          _amount = val;
        });
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Notes'),
      onChanged: (value) => _notes = value,
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.only(left: 60, right: 60, bottom: 30, top: 5),
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) _saveTransaction();
        },
        child: Text(
          'Save',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  _saveTransaction() async {
    _transaction.type = _selectedType;
    _transaction.timestamp = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    _transaction.accountId = _selectedAccount!;
    _transaction.sourceAccountId = _selectedSourceAccount;
    _transaction.categoryId = _selectedCategory;
    _transaction.amount = _amount;
    _transaction.notes = _notes;
    if(_isNew){
      await TransactionEntityService.insertTransaction(_transaction);
    } else {
      await TransactionEntityService.updateTransaction(_transaction, _oldAccountId!, _oldCategoryId, _oldTimestamp!, _oldSourceAccountId);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Transaction'),
          content: Text('This action is irreversible. Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Chiude il popup
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Bottone di eliminazione in rosso
                foregroundColor: Colors.white, // Testo bianco per contrasto
              ),
              onPressed: () {
                _deleteTransaction();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTransaction() async {
    _transaction.accountId = _oldAccountId!;
    _transaction.categoryId = _oldCategoryId;
    await TransactionEntityService.deleteTransaction(_transaction);
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }
}