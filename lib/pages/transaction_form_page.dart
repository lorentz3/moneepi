import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';

class TransactionFormPage extends StatefulWidget {
  final Transaction transaction;
  final bool? isNew;

  const TransactionFormPage({super.key, required this.transaction, required this.isNew});

  @override
  TransactionFormPageState createState() => TransactionFormPageState();
}

class TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  TransactionType _selectedType = TransactionType.EXPENSE;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedAccount;
  int? _selectedCategory;
  double _amount = 0.0;
  String _notes = '';
  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _showTime = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    debugPrint("load data");
    _accounts = await AccountEntityService.getAllAccounts();
    _categories = await CategoryEntityService.getAllCategories(_selectedType);
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
    if (_accounts.isEmpty || _categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Expense')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ToggleButtons(
                isSelected: [_selectedType == TransactionType.EXPENSE, _selectedType == TransactionType.INCOME],
                onPressed: (int index) {
                  setState(() {
                    _selectedType = index == 0 ? TransactionType.EXPENSE : TransactionType.INCOME;    
                    _selectedCategory = null;
                    _loadData();
                  });
                },
                children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Expense')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Income')),
                ],
              ),
              SizedBox(height: 20),
              Text("You still need to configure accounts and/or categories")
            ]
          )
        )
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ToggleButtons(
                  isSelected: [_selectedType == TransactionType.EXPENSE, _selectedType == TransactionType.INCOME],
                  onPressed: (int index) {
                    setState(() {
                      _selectedType = index == 0 ? TransactionType.EXPENSE : TransactionType.INCOME;
                      _selectedCategory = null;
                      _loadData();
                    });
                  },
                  children: [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Text('Expense')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Text('Income')),
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
                        Text(_selectedDate.toLocal().toString().split(' ')[0],
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
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Account'),
                  value: _selectedAccount,
                  items: _accounts.map((account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedAccount = value),
                  validator: (value) => value == null ? 'Choose an account' : null,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 0,
                    children: _accounts.take(5).map((account) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedAccount = account.id;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedAccount == account.id
                              ? Colors.deepPurple[200] // Selected
                              : Colors.grey[300], // Not selected
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(account.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                  ),
                ),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Category'),
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                  validator: (value) => value == null ? 'Choose a category' : null,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 0,
                    children: _categories.take(15).map((category) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = category.id;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedCategory == category.id
                              ? Colors.deepPurple[200]
                              : Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(category.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                  ),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _amount = double.tryParse(value) ?? 0.0,
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

  _saveTransaction() {
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
    transaction.categoryId = _selectedCategory!;
    transaction.amount = _amount;
    transaction.notes = _notes;
    if(widget.isNew!){
      TransactionEntityService.insertTransaction(transaction);
    } else {
      TransactionEntityService.updateTransaction(transaction);
    }
    Navigator.pop(context);
  }
}