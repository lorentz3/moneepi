import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/accounts_page.dart';
import 'package:myfinance2/pages/categories_page.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:excel/excel.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'dart:io';

class ImportXlsMapPage extends StatefulWidget {
  final String filePath;
  final bool hasSubCategories;
  final bool hasHeaderRow;
  final Set<String> distinctAccounts;
  final Set<String> distinctCategories;
  final Map<String, int?> mapColumnIndexes;

  const ImportXlsMapPage({
    super.key, 
    required this.filePath,
    required this.hasHeaderRow,
    required this.distinctAccounts,
    required this.distinctCategories,
    required this.hasSubCategories,
    required this.mapColumnIndexes,
  });

  @override
  ImportXlsMapPageState createState() => ImportXlsMapPageState();
}

// TODO import transfers
class ImportXlsMapPageState extends State<ImportXlsMapPage> {
  String _filePath = "";
  bool _hasSubCategories = false;
  bool _isImporting = false;
  bool _hasHeaderRow = false;
  List<Account> _existingAccounts = [];
  List<Category> _existingCategories = [];
  final Map<String, int?> _accountMapping = {};
  final Map<String, int?> _categoryMapping = {};
  Map<String, int?> _mapColumnIndexes = {};

  @override
  void initState() {
    super.initState();
    _filePath = widget.filePath;
    _hasSubCategories = widget.hasSubCategories;
    _hasHeaderRow = widget.hasHeaderRow;
    _mapColumnIndexes = widget.mapColumnIndexes;
    _loadData();
  }

  Future<void> _loadData() async {
    _existingAccounts = await AccountEntityService.getAllAccounts();
    _existingCategories = await CategoryEntityService.getAllExpenseAndIncomeCategories();
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Map Imported Items")),
      body: Column(
        children: [
          // Non-scrollable header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountsPage(),
                      ),
                    ).then((_) => {
                      setState(() {
                        _loadData();
                      }),
                    });
                  }, // TODO: Navigare alla gestione account
                  child: Text("Manage Accounts"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoriesPage(type: CategoryType.EXPENSE,),
                      ),
                    ).then((_) => {
                      setState(() {
                        _loadData();
                      }),
                    });
                  },
                  child: Text("Manage Categories"),
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Expanded(
            child: ListView(
              children: [
                ...widget.distinctAccounts.map((account) => _buildAccountDropdownRow(account, _accountMapping)),
                ...widget.distinctCategories.map((category) => _buildCategoryDropdownRow(category, _categoryMapping)),
              ],
            ),
          ),
          
          // Fixed footer
          _isImporting ? CircularProgressIndicator() : Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isImporting = true;
                });
                _startImport();
              },
              child: Text("Start Import"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDropdownRow(String importedItem, Map<String, int?> mapping) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              importedItem,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          Expanded(
            child: DropdownButton<int>(
              value: mapping[importedItem],
              hint: Text("Select account"),
              isExpanded: true,
              onChanged: (int? newValue) {
                setState(() {
                  mapping[importedItem] = newValue;
                });
              },
              items: _existingAccounts.map((account) => DropdownMenuItem(
                value: account.id!,
                child: Text("${account.icon ?? ""} ${account.name}"),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryDropdownRow(String importedItem, Map<String, int?> mapping) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              importedItem,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          Expanded(
            child: DropdownButton<int>(
              value: mapping[importedItem],
              hint: Text("Select category"),
              isExpanded: true,
              onChanged: (int? newValue) {
                setState(() {
                  mapping[importedItem] = newValue;
                });
              },
              items: _existingCategories.map((category) => DropdownMenuItem(
                value: category.id!,
                child: Text(
                  "${category.icon ?? ""} ${category.name}",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: category.type == CategoryType.EXPENSE ? Colors.black : Colors.green[900]),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _startImport() async {
    var bytes = File(_filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var sheet = excel.tables.keys.first;
    List<List<dynamic>> rows = excel.tables[sheet]!.rows.map((row) => row.map((cell) => cell?.value).toList()).toList();

    int startRow = _hasHeaderRow ? 1 : 0;
    int dateCol = _mapColumnIndexes['Date']!;
    int? typeCol = _mapColumnIndexes['Type'];
    int accountCol = _mapColumnIndexes['Account']!;
    int? sourceAccountCol = _mapColumnIndexes['Source Account'];
    int categoryCol = _mapColumnIndexes['Category']!;
    int? subCategoryCol = _mapColumnIndexes['SubCategory'];
    int? noteCol = _mapColumnIndexes['Note'];
    int amountCol = _mapColumnIndexes['Amount']!;

    for (var row in rows.skip(startRow)) {
      String importedDate = row[dateCol]?.toString() ?? "";
      String importedType = typeCol != null ? row[typeCol]?.toString() ?? "" : "";
      String importedAccount = row[accountCol]?.toString() ?? "";
      String importedSourceAccount = sourceAccountCol != null ? row[sourceAccountCol]?.toString() ?? "" : "";
      String importedCategory = _hasSubCategories ? "${row[categoryCol]?.toString() ?? ""}/${row[subCategoryCol!]?.toString() ?? ""}" : row[categoryCol]?.toString() ?? "";
      String importedNote = noteCol != null ? row[noteCol]?.toString() ?? "" : "";
      String importedAmount = row[amountCol]?.toString() ?? "";

      int? categoryId = _categoryMapping[importedCategory];
      int? accountId = _accountMapping[importedAccount];
      int? sourceAccountId = _accountMapping[importedSourceAccount];
      if (accountId == null || (categoryId == null && sourceAccountId == null)) {
        continue;
      }
      if (categoryId == null && sourceAccountId != null) {
        await _importTransfer(importedDate, accountId, sourceAccountId, importedAmount, importedNote);
      }
      Category category = _existingCategories.where((category) => category.id == categoryId).first;
      DateFormat format = DateFormat("dd/MM/yyyy HH:mm:ss");
      await TransactionEntityService.insertTransaction(Transaction(
        accountId: accountId,
        timestamp: format.parse(importedDate),
        type: category.type == CategoryType.EXPENSE ? TransactionType.EXPENSE : TransactionType.INCOME,
        categoryId: categoryId,
        amount: double.tryParse(importedAmount) ?? 0.0,
        notes: importedNote,
      ));
    }

    setState(() {
      _isImporting = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("XLSX import completed"))
      );
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  _importTransfer(String importedDate, int accountId, int sourceAccountId, String importedAmount, String? importedNote) async {
    DateFormat format = DateFormat("dd/MM/yyyy HH:mm:ss");
    await TransactionEntityService.insertTransaction(Transaction(
      accountId: accountId,
      timestamp: format.parse(importedDate),
      type: TransactionType.TRANSFER,
      sourceAccountId: sourceAccountId,
      amount: double.tryParse(importedAmount) ?? 0.0,
      notes: importedNote,
    ));
  }
}