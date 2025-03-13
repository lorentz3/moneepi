import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';

import 'package:myfinance2/pages/import_xls_map_page.dart';

class ImportXlsPage extends StatefulWidget {
  const ImportXlsPage({super.key});

  @override
  ImportXlsPageState createState() => ImportXlsPageState();
}

class ImportXlsPageState extends State<ImportXlsPage> {
  String? _filePath;
  bool _hasHeaderRow = true;
  bool _isExtractingAccountsAndCategories = false;
  final Map<String, TextEditingController> columnControllers = {
    'Date': TextEditingController(text: "0"),
    'Account': TextEditingController(text: "1"),
    'Category': TextEditingController(text: "2"),
    'SubCategory': TextEditingController(text: "3"),
    'Note': TextEditingController(text: "4"),
    'Amount': TextEditingController(text: "5"),
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

    var bytes = File(_filePath!).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var sheet = excel.tables.keys.first;
    List<List<dynamic>> rows = excel.tables[sheet]!.rows.map((row) => row.map((cell) => cell?.value).toList()).toList();

    int startRow = _hasHeaderRow ? 1 : 0;
    int? accountCol = int.tryParse(columnControllers['Account']!.text);
    int? categoryCol = int.tryParse(columnControllers['Category']!.text);
    int? subCategoryCol = int.tryParse(columnControllers['SubCategory']!.text);

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
              if (_filePath == null) ElevatedButton(
                onPressed: pickFile,
                child: Text("Select XLSX file"),
              ),
              if (_filePath != null) Text("Selected file: ${_filePath!.split('/').last}", style: TextStyle(fontWeight: FontWeight.bold),),
              SizedBox(height: 8),
              Text("For the best import, the excel file should not have expense categories with the same name of income categories"),
              SizedBox(height: 8),
              Row(
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
              Text("Configure column index (0 = 'A', 1 = 'B', ...):"),
              SizedBox(height: 10),
              ...columnControllers.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextField(
                      controller: entry.value,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "${entry.key} column index: ",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )),
              SizedBox(height: 20),
              if (!_isExtractingAccountsAndCategories) ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isExtractingAccountsAndCategories = true;
                  });
                 _parseFile();
                },
                child: Text("Extract Accounts and Categories"),
              ),
              if (_distinctAccounts.isNotEmpty)
                ...[
                  Text("Accounts found:", style: TextStyle(fontWeight: FontWeight.bold),),
                  ..._distinctAccounts.map((e) => Text(e)),
                ],
              if (_distinctCategories.isNotEmpty)
                ...[
                  Text("Categories found:", style: TextStyle(fontWeight: FontWeight.bold),),
                  ..._distinctCategories.map((e) => Text(e)),
                ],
              SizedBox(height: 20),
              if (_distinctAccounts.isNotEmpty || _distinctCategories.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImportXlsMapPage(
                          filePath: _filePath!,
                          distinctAccounts: _distinctAccounts,
                          distinctCategories: _distinctCategories,
                          hasSubCategories: int.tryParse(columnControllers['SubCategory']!.text) != null,
                          hasHeaderRow: _hasHeaderRow,
                          mapColumnIndexes: _getMapColumnIndexes(),
                        ),
                      ),
                    );
                  },
                  child: Text("Map imported items"),
                ),
              ],
          ),
        ),
      ),
    );
  }
  
  Map<String, int?> _getMapColumnIndexes() {
    return columnControllers.map(
      (key, controller) => MapEntry(key, int.tryParse(controller.text)),
    );
  }
}
