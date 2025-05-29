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

import 'package:myfinance2/widgets/simple_text_button.dart';

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

class ImportXlsMapPageState extends State<ImportXlsMapPage> {
  final DateFormat _dateFormat = DateFormat("dd/MM/yyyy HH:mm:ss");
  String _filePath = "";
  bool _hasSubCategories = false;
  bool _isImporting = false;
  bool _hasHeaderRow = false;
  List<Account> _existingAccounts = [];
  List<Category> _existingCategories = [];
  final Map<String, int?> _accountMapping = {};
  final Map<String, int?> _categoryMapping = {};
  Map<String, int?> _mapColumnIndexes = {};

  final Map<String, List<int>> _importErrors = {};
  final String _dateTimeError = "dateTimeError";
  final String _missingAccountOrCategory = "missingAccountOrCategory";
  final String _transferWithoutSourceAccount = "transferWithoutSourceAccount";
  final String _sameAccountAndSourceAccount = "sameAccountAndSourceAccount";
  final String _categoryNotMapped = "categoryNotMapped";

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
                SimpleTextButton(
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
                  },
                  text: "Manage Accounts",
                ),
                SimpleTextButton(
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
                  text: "Manage Categories",
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Expanded(
            child: ListView(
              children: [
                ...widget.distinctAccounts.map((account) => _buildAccountDropdownRow(account, _accountMapping)),
                SizedBox(height: 15,),
                ...widget.distinctCategories.map((category) => category.isNotEmpty? _buildCategoryDropdownRow(category, _categoryMapping) : SizedBox()),
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
                _startImport(false);
              },
              child: Text("Step 3: Check errors before the real import"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDropdownRow(String importedItem, Map<String, int?> mapping) {
    int? accountFound = _tryToFindMatchingAccount(importedItem);
    if (accountFound != null) {
      mapping[importedItem] = accountFound;
    }
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
    int? categoryFound = _tryToFindMatchingCategory(importedItem);
    if (categoryFound != null) {
      mapping[importedItem] = categoryFound;
    }
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

  void _startImport(bool realImport) async {
    _importErrors[_missingAccountOrCategory] = [];
    _importErrors[_dateTimeError] = [];
    _importErrors[_transferWithoutSourceAccount] = [];
    _importErrors[_sameAccountAndSourceAccount] = [];
    _importErrors[_categoryNotMapped] = [];
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
      startRow++;
      String importedTypeString = typeCol != null ? row[typeCol]?.toString() ?? "" : "";
      String importedAccount = row[accountCol]?.toString() ?? "";
      String importedSourceAccount = sourceAccountCol != null ? row[sourceAccountCol]?.toString() ?? "" : "";
      String importedCategory = _hasSubCategories ? "${row[categoryCol]?.toString() ?? ""}/${row[subCategoryCol!]?.toString() ?? ""}" : row[categoryCol]?.toString() ?? "";
      String importedNote = noteCol != null ? row[noteCol]?.toString() ?? "" : "";
      String importedAmount = row[amountCol]?.toString() ?? "";
      
      DateTime? importedDateTime = parseExcelDate(row[dateCol]);
      if (importedDateTime == null) {
        debugPrint("Failed to import row $startRow: date time not recognized");
        _importErrors.putIfAbsent(_dateTimeError, () => []).add(startRow);
        continue;
      }

      int? categoryId = _categoryMapping[importedCategory];
      int? accountId = _accountMapping[importedAccount];
      int? sourceAccountId = _accountMapping[importedSourceAccount];
      if (accountId == null || (categoryId == null && sourceAccountId == null)) {
        debugPrint("Failed to import row $startRow: missing account or category");
        _importErrors.putIfAbsent(_missingAccountOrCategory, () => []).add(startRow);
        continue;
      }

      if (TransactionType.EXPENSE.name == importedTypeString 
          || TransactionType.INCOME.name == importedTypeString
          || categoryId != null) {
        Category? category = _existingCategories.where((category) => category.id == categoryId).firstOrNull;
        if (category == null) {
          debugPrint("Skipped row $startRow: category not mapped");
          _importErrors.putIfAbsent(_categoryNotMapped, () => []).add(startRow);
          continue;
        }
        if (realImport) {
          await TransactionEntityService.insertTransaction(Transaction(
            accountId: accountId,
            timestamp: importedDateTime,
            type: category.type == CategoryType.EXPENSE ? TransactionType.EXPENSE : TransactionType.INCOME,
            categoryId: categoryId,
            amount: double.tryParse(importedAmount) ?? 0.0,
            notes: importedNote,
          ));
        }
        continue;
      }

      if (TransactionType.TRANSFER.name == importedTypeString || (categoryId == null && sourceAccountId != null)) {
        if (sourceAccountId == null) {
          debugPrint("Failed to import row $startRow: cannot import TRANSFER without sourceAccount");
        _importErrors.putIfAbsent(_transferWithoutSourceAccount, () => []).add(startRow);
          continue;
        }
        if (accountId == sourceAccountId) {
          debugPrint("Failed to import row $startRow: cannot import TRANSFER if sourceAccount and account are the same");
        _importErrors.putIfAbsent(_sameAccountAndSourceAccount, () => []).add(startRow);
          continue;
        }
        if (realImport) {
          await _importTransfer(importedDateTime, accountId, sourceAccountId, importedAmount, importedNote);
          continue;
        }
      }
    }
    setState(() {
      _isImporting = false;
    });

    if (realImport) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("XLSX import completed"))
        );
        Navigator.pop(context);
        Navigator.pop(context, true);
      }
    } else {
      _showRealImportDialog();
    }
  }

  Future<void> _showRealImportDialog() async {
    bool noErrors = (_importErrors[_missingAccountOrCategory] ?? []).isEmpty
      && (_importErrors[_dateTimeError] ?? []).isEmpty
      && (_importErrors[_transferWithoutSourceAccount] ?? []).isEmpty
      && (_importErrors[_sameAccountAndSourceAccount] ?? []).isEmpty
      && (_importErrors[_categoryNotMapped] ?? []).isEmpty;
    String dateTimeErrors = (_importErrors[_dateTimeError] ?? []).isNotEmpty ? "Date time not recognized (rows: ${_formatImportErrors(_dateTimeError)})" : "";
    String missingAccOrCatErrors = (_importErrors[_missingAccountOrCategory] ?? []).isNotEmpty ? "Missing account or category (rows: ${_formatImportErrors(_missingAccountOrCategory)})" : "";
    String transferWithoutSourceAccountErrors = (_importErrors[_transferWithoutSourceAccount] ?? []).isNotEmpty ? "Cannot import TRANSFER without Source Account (rows: ${_formatImportErrors(_transferWithoutSourceAccount)})" : "";
    String sameAccountsErrors = (_importErrors[_sameAccountAndSourceAccount] ?? []).isNotEmpty ? "Cannot import TRANSFER if sourceAccount and account are the same (rows: ${_formatImportErrors(_sameAccountAndSourceAccount)})" : "";
    String categoryNotMappedErrors = (_importErrors[_categoryNotMapped] ?? []).isNotEmpty ? "Category not mapped (rows: ${_formatImportErrors(_categoryNotMapped)})" : "";
    return showDialog<void>(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Import confirmation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(noErrors ? "No errors found. Proceed with the import process?" : "Errors found - some rows will be skipped:"),
                SizedBox(height: 4,),
                if (!noErrors && dateTimeErrors.isNotEmpty) Text(dateTimeErrors),
                SizedBox(height: 4,),
                if (!noErrors && missingAccOrCatErrors.isNotEmpty) Text(missingAccOrCatErrors),
                SizedBox(height: 4,),
                if (!noErrors && transferWithoutSourceAccountErrors.isNotEmpty) Text(transferWithoutSourceAccountErrors),
                SizedBox(height: 4,),
                if (!noErrors && sameAccountsErrors.isNotEmpty) Text(sameAccountsErrors),
                SizedBox(height: 4,),
                if (!noErrors && categoryNotMappedErrors.isNotEmpty) Text(categoryNotMappedErrors),
                SizedBox(height: 4,),
                if (!noErrors) Text("Would you rather update the file and try again later, or continue with the import anyway?"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              child: Text("Start import"),
              onPressed: () {
                setState(() {
                  _startImport(true);
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

  String _formatImportErrors(String key) {
    final list = _importErrors[key];
    if (list == null || list.isEmpty) return '';
    return list.join(', ');
  }

  _importTransfer(DateTime importedDate, int accountId, int sourceAccountId, String importedAmount, String? importedNote) async {
    await TransactionEntityService.insertTransaction(Transaction(
      accountId: accountId,
      timestamp: importedDate,
      type: TransactionType.TRANSFER,
      sourceAccountId: sourceAccountId,
      amount: double.tryParse(importedAmount) ?? 0.0,
      notes: importedNote,
    ));
  }

  DateTime? parseExcelDate(CellValue? cell) {
    if (cell == null) return null;
    switch (cell) {
      case IntCellValue(): 
        const gsDateBase = 2209161600 / 86400;
        const gsDateFactor = 86400000;

        final millis = (cell.value - gsDateBase) * gsDateFactor;
        return DateTime.fromMillisecondsSinceEpoch(millis.toInt());
      case DateCellValue():
        debugPrint('  imported date: ${cell.year} ${cell.month} ${cell.day} (${cell.asDateTimeLocal()})');
        return DateTime(cell.year, cell.month, cell.day);
      case DateTimeCellValue():
        debugPrint('  imported date with time: ${cell.year} ${cell.month} ${cell.day} ${cell.hour} ${cell.minute} ${cell.second} (${cell.asDateTimeLocal()})');
        return DateTime(cell.year, cell.month, cell.day, cell.hour, cell.minute);
      case TextCellValue():
        return _dateFormat.tryParse(cell.value.text ?? "");
      default: 
        return null;
    }
  }
  
  int? _tryToFindMatchingAccount(String nameToMatch) {
    for (Account a in _existingAccounts) {
      if (a.name == nameToMatch) {
        return a.id;
      }
    }
    return null;
  }
  
  int? _tryToFindMatchingCategory(String nameToMatch) {
    for (Category a in _existingCategories) {
      if (a.name == nameToMatch) {
        return a.id;
      }
    }
    return null;
  }
}