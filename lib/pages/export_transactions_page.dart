import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/transaction_export_dto.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportTransactionsPage extends StatefulWidget {
  const ExportTransactionsPage({super.key});

  @override
  State<ExportTransactionsPage> createState() => _ExportTransactionsPageState();
}

class _ExportTransactionsPageState extends State<ExportTransactionsPage> {
  DateTime? fromDate;
  DateTime? toDate;
  bool exportAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Esport Transactions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CheckboxListTile(
              value: exportAll,
              title: Text('Export all'),
              onChanged: (val) => setState(() => exportAll = val ?? false),
            ),
            if (!exportAll) ...[
              ListTile(
                title: Text('From: ${fromDate?.toLocal() ?? "Select date"}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2200),
                  );
                  if (picked != null) setState(() => fromDate = picked);
                },
              ),
              ListTile(
                title: Text('To: ${toDate?.toLocal() ?? "Select date"}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => toDate = picked);
                },
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
    );
  }

  Future<void> _export() async {
    if (!exportAll && (fromDate == null || toDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Select both 'From' and 'To', or export all")),
      );
      return;
    }
    // Recupera i dati con i join
    final transactions = await TransactionEntityService.getTransactionsForExport(
      from: exportAll ? null : fromDate,
      to: exportAll ? null : toDate,
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

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final fileBytes = excel.encode()!;
    final file = File(filePath)..createSync(recursive: true)..writeAsBytesSync(fileBytes);
    return file;
  }
}
