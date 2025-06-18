import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/transaction_export_dto.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/configuration.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/configuration_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/utils/date_utils.dart';
import 'package:myfinance2/widgets/simple_text_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportTransactionsPage extends StatefulWidget {
  const ExportTransactionsPage({super.key});

  @override
  State<ExportTransactionsPage> createState() => _ExportTransactionsPageState();
}

class _ExportTransactionsPageState extends State<ExportTransactionsPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _exportAll = false;
  final bool _exportCategories = true;
  final bool _exportAccounts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('XLSX Export')),
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CheckboxListTile(
                value: _exportAll,
                title: Text(
                  'Export all transactions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                  ),
                ),
                onChanged: (val) => setState(() => _exportAll = val ?? false),
              ),
              if (!_exportAll) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 30,),
                    Text(
                      'From: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    ),
                    SizedBox(width: 10,),
                    _fromDate != null ? Text(
                      '${MyDateUtils.formatDate(_fromDate)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    ) : SizedBox(),
                    SizedBox(width: 10,),
                    _fromDate != null ? Expanded(child: SizedBox()) : SizedBox(),
                    SimpleTextButton(
                      text: "Select date",
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime(2200),
                        );
                        if (picked != null) setState(() => _fromDate = picked);
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 30,),
                    Text(
                      'To:     ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    ),
                    SizedBox(width: 10,),
                    _toDate != null ? Text(
                      '${MyDateUtils.formatDate(_toDate)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    ) : SizedBox(),
                    SizedBox(width: 10,),
                    _toDate != null ? Expanded(child: SizedBox()) : SizedBox(),
                    SimpleTextButton(
                      text: "Select date",
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime(2200),
                        );
                        if (picked != null) setState(() => _toDate = picked);
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _export(),
                icon: Icon(Icons.download),
                label: Text('Export'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export() async {
    if (!_exportAll && (_fromDate == null || _toDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Select both 'From' and 'To', or export all")),
      );
      return;
    }
    // Recupera i dati con i join
    final transactions = await TransactionEntityService.getTransactionsForExport(
      from: _exportAll ? null : _fromDate,
      to: _exportAll ? null : _toDate,
    );

    final file = await exportTransactionsToExcel(transactions);
    // Poi condividi o apri
    await Future.delayed(Duration(milliseconds: 100));
    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint('Errore nella condivisione: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error while sharing file on this device.')),
      );
    }
  }

  Future<File> exportTransactionsToExcel(List<TransactionExportDto> transactions) async {
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];
    // Rimuove il foglio 'Sheet1' di default, se presente
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow([TextCellValue('Date'), TextCellValue('Type'), TextCellValue('Account'), TextCellValue('SourceAccount'),
      TextCellValue('Category'), TextCellValue('Amount'), TextCellValue('Notes')]);

    DateFormat dateFormat = DateFormat("dd/MM/yyyy hh:mm:ss");
    for (var tx in transactions) {
      String type = tx.type;
      sheet.appendRow([
        TextCellValue(dateFormat.format(tx.date)),
        TextCellValue(type),
        TextCellValue(tx.account ?? ''),
        TextCellValue(type == 'TRANSFER' ? tx.sourceAccount ?? '' : ''),
        TextCellValue(tx.category ?? ''),
        DoubleCellValue(tx.amount),
        TextCellValue(tx.notes ?? ''),
      ]);
    }

    if (_exportCategories) {
  	  final expenseCategoriesSheet = excel['Expense_Categories'];
      expenseCategoriesSheet.appendRow([TextCellValue('Icon'), TextCellValue('Name'), TextCellValue('Order'), TextCellValue('Month Threshold')]);

      List<Category> expenseCategories = await CategoryEntityService.getAllCategories(CategoryType.EXPENSE);
      for (var c in expenseCategories) {
        expenseCategoriesSheet.appendRow([
          TextCellValue(c.icon ?? ''),
          TextCellValue(c.name),
          TextCellValue("${c.sort}"),
          TextCellValue("${c.monthThreshold ?? ''}"),
        ]);
      }
  	  final incomeCategoriesSheet = excel['Income_Categories'];
      incomeCategoriesSheet.appendRow([TextCellValue('Icon'), TextCellValue('Name'), TextCellValue('Order')]);

      List<Category> incomeCategories = await CategoryEntityService.getAllCategories(CategoryType.INCOME);
      for (var c in incomeCategories) {
        incomeCategoriesSheet.appendRow([
          TextCellValue(c.icon ?? ''),
          TextCellValue(c.name),
          TextCellValue("${c.sort}"),
        ]);
      }
    }

    if (_exportAccounts) {
  	  final accountsSheet = excel['Accounts'];
      accountsSheet.appendRow([TextCellValue('Icon'), TextCellValue('Name'), TextCellValue('Order'), TextCellValue('Initial Balance')]);

      List<Account> accounts = await AccountEntityService.getAllAccounts();
      for (var a in accounts) {
        accountsSheet.appendRow([
          TextCellValue(a.icon ?? ''),
          TextCellValue(a.name),
          TextCellValue("${a.sort}"),
          TextCellValue("${a.initialBalance}"),
        ]);
      }
    }

    final configSheet = excel['Configurations'];
    configSheet.appendRow([TextCellValue('Name'), TextCellValue('intValue'), TextCellValue('textValue'), TextCellValue('realValue')]);
    List<Configuration> configs = await ConfigurationEntityService.getAllConfigurations();
    for (var a in configs) {
      configSheet.appendRow([
        TextCellValue(a.name),
        TextCellValue("${a.intValue ?? ''}"),
        TextCellValue(a.textValue ?? ''),
        TextCellValue("${a.realValue ?? ''}"),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final fileBytes = excel.encode()!;
    final file = File(filePath)..createSync(recursive: true)..writeAsBytesSync(fileBytes);
    return file;
  }
}
