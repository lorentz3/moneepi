import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/widgets/emoji_button.dart';
import 'package:myfinance2/widgets/section_divider.dart';

class TransactionFormPage extends StatefulWidget {
  final int? transactionId;
  final Transaction? transaction;
  final bool isNew;

  const TransactionFormPage({super.key, this.transactionId, this.transaction, required this.isNew,});

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
  double? _amount;
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
  bool _showTime = false; // TODO config
  bool _showDropdownMenus = false; // TODO config
  bool _showTiles = true; // TODO config

  @override
  void initState() {
    super.initState();
    _isNew = widget.isNew;
    if (_isNew) {
      _transaction = widget.transaction!;
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
    _amount = _transaction.amount;
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
      _selectedAccount ??= _accounts[0].id;
      _selectedSourceAccount ??= _accounts[0].id;
    }
    if (_categories.isNotEmpty) {
      _selectedCategory ??= _categories[0].id;
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: _isNew ? Text('New transaction') : Text('Edit transaction')),
        body: Center(child: CircularProgressIndicator())
      );
    }
    if (_accounts.isEmpty || _categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: _isNew ? Text('New transaction') : Text('Edit transaction')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ToggleButtons(
                isSelected: [_selectedType == TransactionType.EXPENSE, _selectedType == TransactionType.INCOME, _selectedType == TransactionType.TRANSFER],
                onPressed: (int index) {
                  setState(() {
                    _selectedType = index == 0 ? TransactionType.EXPENSE : 
                      index == 1 ? TransactionType.INCOME : TransactionType.TRANSFER;
                    _selectedCategory = null;
                    _selectedAccount = null;
                    _loadData();
                  });
                },
                children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Expense')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Income')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Transfer')),
                ],
              ),
              SizedBox(height: 20),
              Text("You still need to configure accounts and/or categories")
            ]
          )
        )
      );
    }
    final double padding = 16.0;
    int buttonsPerRow = 6;
    double spaceBetweenButtons = 6;
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonSize = (screenWidth - (buttonsPerRow * spaceBetweenButtons) - padding - 10) / buttonsPerRow;
    return Scaffold(
      appBar: AppBar(
        title: _isNew ? Text('New transaction') : Text('Edit transaction'),
        actions: [
          _isNew ? SizedBox(height: 1,) : IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ToggleButtons(
                  isSelected: [_selectedType == TransactionType.EXPENSE, _selectedType == TransactionType.INCOME, _selectedType == TransactionType.TRANSFER],
                  onPressed: (int index) {
                    setState(() {
                      _selectedType = index == 0 ? TransactionType.EXPENSE : 
                        index == 1 ? TransactionType.INCOME : TransactionType.TRANSFER;
                      _selectedCategory = null;
                      _loadData();
                    });
                  },
                  children: [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Text('Expense')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Text('Income')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Transfer')),
                  ],
                ),
                SizedBox(height: 5,),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text("Date: "),
                        Text(_selectedDate.toLocal().toString().split(' ')[0], //TODO date format
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(width: 10,),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                _showTime ? ListTile(
                  title: Text("Time: ${_selectedTime.format(context)}"),
                  trailing: Icon(Icons.access_time),
                  onTap: () => _selectTime(context),
                ) : SizedBox(height: 0,),

                // source account
                _selectedType == TransactionType.TRANSFER ? 
                  _showDropdownMenus ?
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: 'Source account'),
                    value: _selectedSourceAccount,
                    items: _accounts.map((account) {
                      String accountTitle = account.icon != null ? "${account.icon!} ${account.name}" : account.name;
                      return DropdownMenuItem<int>(
                        value: account.id,
                        child: Text(accountTitle),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSourceAccount = value),
                    validator: (value) => value == null ? 'Choose an account' : null,
                  ) : SectionDivider(text: 'Source account') : SizedBox(height: 1,),
                  //source account tiles
                  _showTiles && _selectedType == TransactionType.TRANSFER ? Align(
                    alignment: Alignment.center,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _accounts.take(5).map((account) {
                        return EmojiButton(
                          icon: account.icon != null ? account.icon! : account.name.substring(0, 2),
                          label: account.name,
                          width: buttonSize,
                          height: buttonSize,
                          onPressed: () {
                            setState(() {
                              _selectedSourceAccount = account.id;
                            });
                          },
                          backgroundColor: _selectedSourceAccount == account.id
                                ? _selectedButtonColor // Selected
                                : _notSelectedButtonColor,
                        );
                      }).toList(),
                    ),
                  ) : SizedBox(height: 1,),

                // target account
                _showDropdownMenus ? DropdownButtonFormField<int>(
                  decoration: _selectedType != TransactionType.TRANSFER ? InputDecoration(labelText: 'Account') : InputDecoration(labelText: 'Target account') ,
                  value: _selectedAccount,
                  items: _accounts.map((account) {
                    String accountTitle = account.icon != null ? "${account.icon!} ${account.name}" : account.name;
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(accountTitle),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedAccount = value),
                  validator: (value) => value == null ? 'Choose an account' : null,
                ) : SectionDivider(text: _selectedType != TransactionType.TRANSFER ? 'Account' : 'Target account'),
                //target account tiles
                _showTiles ? Align(
                  alignment: Alignment.center,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _accounts.map((account) {
                      return EmojiButton(
                        icon: account.icon != null ? account.icon! : account.name.substring(0, 2),
                        label: account.name,
                        width: buttonSize,
                        height: buttonSize,
                        onPressed: () {
                          setState(() {
                            _selectedAccount = account.id;
                          });
                        },
                        backgroundColor: _selectedAccount == account.id
                              ? _selectedButtonColor// Selected
                              : _notSelectedButtonColor,
                      );
                    }).toList(),
                  ),
                ) : SizedBox(height: 1,),

                // category
                _selectedType != TransactionType.TRANSFER ?
                  _showDropdownMenus ? DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Category'),
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    String categoryTitle = category.icon != null ? "${category.icon!} ${category.name}" : category.name;
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(categoryTitle),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                  validator: (value) => value == null ? 'Choose a category' : null,
                ) : SectionDivider(text: 'Category') : SizedBox(height: 1,),
                // category buttons
                SizedBox(height: spaceBetweenButtons,),
                _showTiles && _selectedType != TransactionType.TRANSFER ? Align(
                  alignment: Alignment.center,
                  child: Wrap(
                    spacing: spaceBetweenButtons,
                    runSpacing: spaceBetweenButtons,
                    children: _categories.map((category) {
                      return EmojiButton(
                        icon: category.icon != null ? category.icon! : category.name.substring(0, 2),
                        label: category.name,
                        width: buttonSize,
                        height: buttonSize,
                        onPressed: () {
                          setState(() {
                            _selectedCategory = category.id;
                          });
                        },
                        backgroundColor: _selectedCategory == category.id
                              ? _selectedButtonColor // Selected
                              : _notSelectedButtonColor,
                      );
                    }).toList(),
                  ),
                ) : SizedBox(height: 1,),
                
                //amount
                TextFormField(
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  initialValue: _amount != null ? "$_amount" : "",
                  onChanged: (value) => _amount = double.tryParse(_replaceCommaWithPoint(value)) ?? 0.0,
                  validator: (value) => value == null || double.tryParse(_replaceCommaWithPoint(value)) == null || value == '' ? 'Insert a valid amount' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Notes'),
                  onChanged: (value) => _notes = value,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _saveTransaction();
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _replaceCommaWithPoint(String value) {
    return value.replaceAll(",", ".");
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