import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';

import 'package:myfinance2/pages/import_xls_map_page.dart';
import 'package:myfinance2/widgets/info_label.dart';
import 'package:myfinance2/widgets/simple_text_button.dart';

class ImportXlsPage extends StatefulWidget {
  const ImportXlsPage({super.key});

  @override
  ImportXlsPageState createState() => ImportXlsPageState();
}

class ImportXlsPageState extends State<ImportXlsPage> {
  String? _filePath;
  bool _importingFromMoneePi = true;
  bool _hasHeaderRow = true;
  bool _isExtractingAccountsAndCategories = false;
  final Map<String, TextEditingController> _columnControllers = {
    'Date': TextEditingController(text: "0"),
    'Type': TextEditingController(text: "1"),
    'Account': TextEditingController(text: "2"),
    'Source Account': TextEditingController(text: "3"),
    'Category': TextEditingController(text: "4"),
    'SubCategory': TextEditingController(text: ""),
    'Amount': TextEditingController(text: "5"),
    'Note': TextEditingController(text: "6"),
  };
  final Map<String, bool> _mandatoryIndex = {
    'Date': true,
    'Type': false,
    'Account': true,
    'Source Account': false,
    'Category': true,
    'SubCategory': false,
    'Amount': true,
    'Note': false,
  };
  final Set<String> _distinctAccounts = {};
  final Set<String> _distinctCategories = {};

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
    }
  }

  void _parseFile() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Select a .xlsx file before"))
      );
      setState(() {
        _isExtractingAccountsAndCategories = false;
      });
      return;
    }

    Excel excel;
    try {
      var bytes = File(_filePath!).readAsBytesSync();
      excel = Excel.decodeBytes(bytes);
    } catch (e, stacktrace) {
      debugPrint('Error while reading excel file: $e, $stacktrace');
      // Mostra il messaggio a schermo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error while reading the file: try to copy/paste your rows in a new xlsx file'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isExtractingAccountsAndCategories = false;
      });
      return;
    }
    var sheet = excel.tables.keys.first;
    List<List<dynamic>> rows = excel.tables[sheet]!.rows.map((row) => row.map((cell) => cell?.value).toList()).toList();

    int startRow = _hasHeaderRow ? 1 : 0;
    int? accountCol = int.tryParse(_columnControllers['Account']!.text);
    int? categoryCol = int.tryParse(_columnControllers['Category']!.text);
    int? subCategoryCol = int.tryParse(_columnControllers['SubCategory']!.text);

    if (accountCol == null || categoryCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Missing Account/Category column configuration"))
      );
      return;
    }

    for (var row in rows.skip(startRow)) {
      if (row.length > accountCol) {
        _distinctAccounts.add(row[accountCol]?.toString() ?? "");
      }
      if (subCategoryCol != null) {
        if (row.length > categoryCol) {
          _distinctCategories.add("${row[categoryCol]?.toString() ?? ""}/${row[subCategoryCol]?.toString() ?? ""}");
        }
      } else {
        if (row.length > categoryCol) {
          _distinctCategories.add(row[categoryCol]?.toString() ?? "");
        }
      }
    }

    setState(() {
      _isExtractingAccountsAndCategories = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("XLSX Import settings")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isExtractingAccountsAndCategories
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Importing accounts and categories..."),
                  ],
                ),
              )
            : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLabel(
                text: "For the best import, the excel file should not have expense categories with the same name of income categories.",
                fontSize: 12,
              ),
              SimpleTextButton(
                onPressed: pickFile,
                text: _filePath == null ? "Select XLSX file" : "Select another XLSX file",
              ),
              SizedBox(height: 2),
              if (_filePath != null) Text("Selected file: ${_filePath!.split('/').last}", style: TextStyle(fontWeight: FontWeight.bold),),
              SizedBox(height: 2),
              Row(
                children: [
                  Checkbox(
                    value: _importingFromMoneePi,
                    onChanged: (bool? value) {
                      setState(() {
                        _importingFromMoneePi = value ?? true;
                      });
                    },
                  ),
                  Text("I'm importing data from MoneePi export"),
                ],
              ),
              if (!_importingFromMoneePi) Row(
                children: [
                  Checkbox(
                    value: _hasHeaderRow,
                    onChanged: (bool? value) {
                      setState(() {
                        _hasHeaderRow = value ?? true;
                      });
                    },
                  ),
                  Text("The file contains a header row")
                ],
              ),
              if (!_importingFromMoneePi) InfoLabel(
                text: "Configure column index (0 = 'A', 1 = 'B', ...). If you are importing a file exported from this app, you can leave default indexes and go ahead.",
                fontSize: 12,
              ),
              if (!_importingFromMoneePi)
              SizedBox(height: 10),
              if (!_importingFromMoneePi)
              ..._columnControllers.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      children: [
                        if (entry.key == 'Date') InfoLabel(
                          text: "'Date' column must be a date cell type, or a date in 'dd/MM/yyyy HH:mm:ss' format",
                          fontSize: 12,
                        ),
                        if (entry.key == 'Date') SizedBox(height: 8),
                        if (entry.key == 'Type') InfoLabel(
                          text: "'Type' column must contain 'EXPENSE', 'INCOME' or 'TRANSFER', in order to distinguish the types of transactions. You can leave it empty, transaction type will be deducted by the target category type and the source account presence.",
                          fontSize: 12,
                        ),
                        if (entry.key == 'Type') SizedBox(height: 8),
                        if (entry.key == 'Source Account') InfoLabel(
                          text: "You need 'Source Account' column only if you are interested in importing TRANSFERs (movements from a Source Account to another Account)",
                          fontSize: 12,
                        ),
                        if (entry.key == 'Source Account') SizedBox(height: 8),
                        if (entry.key == 'SubCategory') InfoLabel(
                          text: "You need 'Sub Categories' column only if you are importing an xlsx file from some app that uses also Sub Categories.",
                          fontSize: 12,
                        ),
                        if (entry.key == 'SubCategory') SizedBox(height: 8),
                        TextField(
                          controller: entry.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "${entry.key} column index${isMandatory(entry.key) ? " (*) " : ""}: ",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ]
                    )
                  )),
              SizedBox(height: 20),
              if (!_importingFromMoneePi && !_isExtractingAccountsAndCategories && _distinctAccounts.isEmpty) ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isExtractingAccountsAndCategories = true;
                  });
                 _parseFile();
                },
                child: Text("Step 1: Extract Accounts and Categories"),
              ),
              if (!_importingFromMoneePi && _distinctAccounts.isNotEmpty)
                ...[
                  Text("Accounts found:", style: TextStyle(fontWeight: FontWeight.bold),),
                  ..._distinctAccounts.map((e) => Text(e)),
                ],
              if (!_importingFromMoneePi && _distinctCategories.isNotEmpty)
                ...[
                  Text("Categories found:", style: TextStyle(fontWeight: FontWeight.bold),),
                  ..._distinctCategories.map((e) => Text(e)),
                ],
              SizedBox(height: 20),
              if (_filePath != null && (_importingFromMoneePi || _distinctAccounts.isNotEmpty || _distinctCategories.isNotEmpty))
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImportXlsMapPage(
                          filePath: _filePath!,
                          distinctAccounts: _distinctAccounts,
                          distinctCategories: _distinctCategories,
                          hasSubCategories: int.tryParse(_columnControllers['SubCategory']!.text) != null,
                          hasHeaderRow: _hasHeaderRow,
                          importingFromMoneePi: _importingFromMoneePi,
                          mapColumnIndexes: _getMapColumnIndexes(),
                        ),
                      ),
                    );
                  },
                  child: _importingFromMoneePi ? 
                    Text("Next step") : 
                    Text("Step 2: Map imported items"),
                ),
              ],
          ),
        ),
      ),
    );
  }
  
  Map<String, int?> _getMapColumnIndexes() {
    return _columnControllers.map(
      (key, controller) => MapEntry(key, int.tryParse(controller.text)),
    );
  }

  bool isMandatory(String fieldName) {
    return _mandatoryIndex[fieldName]!;
  }
}
