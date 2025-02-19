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
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int? _selectedAccount;
  int? _selectedCategory;
  double _amount = 0.0;
  String _notes = '';
  List<Account>? accounts = [];
  List<Category>? categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    accounts = await AccountEntityService.getAllAccounts();
    categories = await CategoryEntityService.getAllCategories(_selectedType);
    setState(() { });
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, selectedTime.hour, selectedTime.minute);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
        selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (accounts == null || categories == null) {
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
                      _loadData();
                    });
                  },
                  children: [
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Expense')),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Income')),
                  ],
                ),
                ListTile(
                  title: Text("Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                ListTile(
                  title: Text("Time: ${selectedTime.format(context)}"),
                  trailing: Icon(Icons.access_time),
                  onTap: () => _selectTime(context),
                ),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Account'),
                  value: _selectedAccount,
                  items: accounts!.map((account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedAccount = value),
                  validator: (value) => value == null ? 'Choose an account' : null,
                ),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Category'),
                  value: _selectedCategory,
                  items: categories!.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                  validator: (value) => value == null ? 'Choose a category' : null,
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
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
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