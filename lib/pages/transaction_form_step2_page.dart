import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/transaction_form_step1_page.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/utils/color_identity.dart';
import 'package:myfinance2/utils/date_utils.dart';
import 'package:myfinance2/widgets/amount_input_field.dart';
import 'package:myfinance2/widgets/footer_button.dart';

class TransactionFormStep2Page extends StatefulWidget {
  final int? transactionId;
  final Transaction transaction;
  final bool isNew;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final int? selectedAccount;
  final int? selectedSourceAccount;
  final int? selectedCategory;
  final double amount;
  final String? notes;
  final int? oldAccountId;
  final int? oldCategoryId;
  final DateTime? oldTimestamp;
  final int? oldSourceAccountId;

  const TransactionFormStep2Page({
    super.key,
    this.transactionId,
    required this.transaction,
    required this.isNew,
    required this.selectedDate,
    required this.selectedTime,
    this.selectedAccount,
    this.selectedSourceAccount,
    this.selectedCategory,
    required this.amount,
    this.notes,
    this.oldAccountId,
    this.oldCategoryId,
    this.oldTimestamp,
    this.oldSourceAccountId,
  });

  @override
  TransactionFormStep2PageState createState() => TransactionFormStep2PageState();
}

class TransactionFormStep2PageState extends State<TransactionFormStep2Page> {
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
  Account? _selectedAccountObject;
  Account? _selectedSourceAccountObject;
  Category? _selectedCategoryObject;
  bool _isLoading = true;
  final bool _showTime = true;
  bool _multipleAccounts = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.transaction.type;
    _selectedDate = widget.selectedDate;
    _selectedTime = widget.selectedTime;
    _selectedAccount = widget.selectedAccount;
    _selectedSourceAccount = widget.selectedSourceAccount;
    _selectedCategory = widget.selectedCategory;
    _amount = widget.amount;
    _notes = widget.notes;
    _loadData();
  }

  Future<void> _loadData() async {
    _accounts = await AccountEntityService.getAllAccounts();
    
    if (_accounts.isNotEmpty) {
      if (_accounts.length > 1) {
        _multipleAccounts = true;
      }
    }
    
    // Load the selected account and category objects
    if (_selectedAccount != null) {
      _selectedAccountObject = _accounts.firstWhere((a) => a.id == _selectedAccount, orElse: () => _accounts.first);
    }
    
    if (_selectedSourceAccount != null) {
      _selectedSourceAccountObject = _accounts.firstWhere((a) => a.id == _selectedSourceAccount, orElse: () => _accounts.first);
    }
    
    if (_selectedCategory != null) {
      _selectedCategoryObject = await CategoryEntityService.getCategoryById(_selectedCategory!);
    }
    
    _isLoading = false;
    setState(() {});
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

  Future<void> _navigateToStep1() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormStep1Page(
          transaction: widget.transaction,
          isNew: widget.isNew,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedAccount: _selectedAccount,
          selectedSourceAccount: _selectedSourceAccount,
          selectedCategory: _selectedCategory,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedDate = result['selectedDate'];
        _selectedTime = result['selectedTime'];
        _selectedAccount = result['selectedAccount'];
        _selectedSourceAccount = result['selectedSourceAccount'];
        _selectedCategory = result['selectedCategory'];
      });
      await _loadData(); // Reload to update displayed account/category objects
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScaffold();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDateTimeRow(context),
                  SizedBox(height: 12),
                  _buildSelectedAccountCategoryRow(),
                  SizedBox(height: 20),
                  _buildAmountField(),
                  _buildNotesField(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: _buildSaveButton(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.isNew ? 'New ${getTransactionTypeText(_selectedType)}' : 'Edit ${getTransactionTypeText(_selectedType)}'),
      actions: [
        if (!widget.isNew)
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmationDialog(context),
          ),
      ],
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text('Loading...')),
      body: Center(child: CircularProgressIndicator()),
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

  Widget _buildSelectedAccountCategoryRow() {
    return InkWell(
      onTap: _navigateToStep1,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildRowContent(),
            ),
            Icon(Icons.edit, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildRowContent() {
    List<Widget> items = [];
    
    // For transfers, show source and target accounts
    if (_selectedType == TransactionType.TRANSFER) {
      if (_selectedSourceAccountObject != null) {
        items.add(_buildItemChip(
          icon: _selectedSourceAccountObject!.icon ?? '💰',
          name: _selectedSourceAccountObject!.name,
          prefix: 'From: ',
        ));
      }
      if (_selectedAccountObject != null) {
        items.add(_buildItemChip(
          icon: _selectedAccountObject!.icon ?? '💰',
          name: _selectedAccountObject!.name,
          prefix: 'To: ',
        ));
      }
    } else {
      // For expense/income, show account (if multiple) and category
      if (_multipleAccounts && _selectedAccountObject != null) {
        items.add(_buildItemChip(
          icon: _selectedAccountObject!.icon ?? '💰',
          name: _selectedAccountObject!.name,
        ));
      }
      if (_selectedCategoryObject != null) {
        items.add(_buildItemChip(
          icon: _selectedCategoryObject!.icon ?? '📁',
          name: _selectedCategoryObject!.name,
        ));
      }
    }
    
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _buildItemChip({required String icon, required String name, String? prefix}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(width: 6),
        Text(
          '${prefix ?? ''}$name',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
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
      initialValue: _notes,
    );
  }

  Widget _buildSaveButton() {
    bool isSaveEnabled = _selectedType == TransactionType.TRANSFER
        ? _selectedAccount != null && _selectedSourceAccount != null
        : _selectedAccount != null && _selectedCategory != null;
    
    return Container(
      color: backgroundGrey(),
      padding: EdgeInsets.only(left: 80, right: 80, bottom: 6, top: 6),
      child: FooterButton(
        text: "Save",
        onPressed: isSaveEnabled
            ? () {
                if (_formKey.currentState!.validate()) _saveTransaction();
              }
            : null,
        color: isSaveEnabled ? deepPurple() : backgroundGrey()
      ),
    );
  }

  _saveTransaction() async {
    bool isTransfer = _selectedType == TransactionType.TRANSFER;
    Transaction transaction = widget.transaction;
    transaction.type = _selectedType;
    transaction.timestamp = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    transaction.accountId = _selectedAccount!;
    transaction.sourceAccountId = isTransfer ? _selectedSourceAccount : null;
    transaction.categoryId = !isTransfer ? _selectedCategory : null;
    transaction.amount = _amount;
    transaction.notes = _notes;
    
    if (widget.isNew) {
      await TransactionEntityService.insertTransaction(transaction, true);
    } else {
      await TransactionEntityService.updateTransaction(
        transaction,
        widget.oldAccountId!,
        widget.oldCategoryId,
        widget.oldTimestamp!,
        widget.oldSourceAccountId
      );
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
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
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
    Transaction transaction = widget.transaction;
    transaction.accountId = widget.oldAccountId!;
    transaction.categoryId = widget.oldCategoryId;
    await TransactionEntityService.deleteTransaction(transaction);
    if (mounted) {
      Navigator.pop(context); // Close the dialog
      Navigator.pop(context); // Close the step 2 page
    }
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