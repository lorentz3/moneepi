import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';

class ImportXlsPage extends StatefulWidget {
  const ImportXlsPage({super.key});

  @override
  ImportXlsPageState createState() => ImportXlsPageState();
}

class ImportXlsPageState extends State<ImportXlsPage> {
  String? filePath;
  bool hasHeaderRow = true;
  bool isImporting = false;
  final Map<String, TextEditingController> columnControllers = {
    'Date': TextEditingController(text: "0"),
    'Account': TextEditingController(text: "1"),
    'Category': TextEditingController(text: "2"),
    'SubCategory': TextEditingController(text: "3"),
    'Note': TextEditingController(text: "4"),
    'Amount': TextEditingController(text: "5"),
  };
  Set<String> distinctAccounts = {};
  Set<String> distinctCategories = {};
  Set<String> distinctSubCategories = {};

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xls', 'xlsx']);
    if (result != null) {
      setState(() {
        filePath = result.files.single.path;
      });
    }
  }

  void _parseFile() async {
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Seleziona un file prima di continuare"))
      );
      return;
    }
    setState(() {
      isImporting = true;
    });

    var bytes = File(filePath!).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var sheet = excel.tables.keys.first;
    List<List<dynamic>> rows = excel.tables[sheet]!.rows.map((row) => row.map((cell) => cell?.value).toList()).toList();

    int startRow = hasHeaderRow ? 1 : 0;
    int? accountCol = int.tryParse(columnControllers['Account']!.text);
    int? categoryCol = int.tryParse(columnControllers['Category']!.text);
    int? subCategoryCol = int.tryParse(columnControllers['SubCategory']!.text);

    if (accountCol == null || categoryCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Configura correttamente le colonne prima di continuare"))
      );
      return;
    }

    for (var row in rows.skip(startRow)) {
      if (row.length > accountCol) {
        distinctAccounts.add(row[accountCol]?.toString() ?? "");
      }
      if (row.length > categoryCol) {
        distinctCategories.add(row[categoryCol]?.toString() ?? "");
      }
      if (subCategoryCol != null && row.length > subCategoryCol) {
        distinctSubCategories.add(row[subCategoryCol]?.toString() ?? "");
      }
    }

    setState(() {
      isImporting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Importa XLS")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isImporting
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
              if (filePath == null) ElevatedButton(
                onPressed: pickFile,
                child: Text("Select XLSX file"),
              ),
              if (filePath != null) Text("Selected file: ${filePath!.split('/').last}", style: TextStyle(fontWeight: FontWeight.bold),),
              SizedBox(height: 10),
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
              ElevatedButton(
                onPressed: _parseFile,
                child: Text("Extract Accounts and Categories"),
              ),
              if (distinctAccounts.isNotEmpty)
                ...[
                  Text("Accounts found:", style: TextStyle(fontWeight: FontWeight.bold),),
                  ...distinctAccounts.map((e) => Text(e)),
                ],
              if (distinctCategories.isNotEmpty)
                ...[
                  Text("Categories found:", style: TextStyle(fontWeight: FontWeight.bold),),
                  ...distinctCategories.map((e) => Text(e)),
                ],
              if (distinctSubCategories.isNotEmpty)
                ...[
                  Text("Sub-categories found:", style: TextStyle(fontWeight: FontWeight.bold),),
                  ...distinctSubCategories.map((e) => Text(e)),
                ],
              SizedBox(height: 20),
              if (distinctAccounts.isNotEmpty || distinctCategories.isNotEmpty)
                ElevatedButton(
                  onPressed: () {}, // Da implementare: passaggio alla schermata di mappatura
                  child: Text("Map imported items"),
                ),
              ],
          ),
        ),
      ),
    );
  }
}
