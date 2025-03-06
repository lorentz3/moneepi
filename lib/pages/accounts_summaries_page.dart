import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/monthly_account_summary_dto.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/monthly_account_entity_service.dart';

class AccountSummaryPage extends StatefulWidget {

  const AccountSummaryPage({
    super.key,
  });
  
  @override
  State<AccountSummaryPage> createState() => AccountSummaryPageState();
}

class AccountSummaryPageState extends State<AccountSummaryPage> {
  late DateTime _selectedDate;
  List<MonthlyAccountSummaryDto> _monthlySummaries = [];
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadAllData();
  }

  _loadAllData() async {
    _accounts = await AccountEntityService.getAllAccounts();
    _monthlySummaries = await MonthlyAccountEntityService.getAllMonthAccountsSummaries(_selectedDate.month, _selectedDate.year);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accounts summary")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCurrentBalances(),
            SizedBox(height: 16),
            _buildBalanceChart(),
            SizedBox(height: 16),
            _buildMonthlySummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBalances() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Saldi Attuali", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Column(
              children: _accounts.map((account) => ListTile(
                title: account.icon != null ? Text("${account.icon} ${account.name}") : Text(account.name),
                trailing: Text("€ ${account.balance.toStringAsFixed(2)}"),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Riepilogo Mensile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Placeholder(fallbackHeight: 40), // Qui va il tuo selettore di mese
            SizedBox(height: 8),
            Column(
              children: _monthlySummaries.map((summary) => ListTile(
                leading: summary.accountIcon != null ? Icon(Icons.account_balance) : null,
                title: Text(summary.accountName),
                subtitle: Text("Mese: ${summary.month}/${summary.year}"),
                trailing: Text("€${summary.amount?.toStringAsFixed(2) ?? '0.00'}"),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceChart() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Andamento Bilancio", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Text("€${value.toStringAsFixed(0)}", style: TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < 12) {
                            DateTime now = DateTime.now();
                            DateTime monthDate = DateTime(now.year, now.month - 11 + index);
                            return Text(DateFormat('MMM').format(monthDate), style: TextStyle(fontSize: 10));
                          }
                          return Text('');
                        },
                      ),
                    ),
                  ),
                  lineBarsData: _generateLineChartData(),
                  minY: 0,
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _generateLineChartData() {
    DateTime now = DateTime.now();
    List<int> last12Months = List.generate(12, (index) => now.month - 11 + index);
    List<int> last12Years = List.generate(12, (index) => now.year - (now.month - 11 + index < 1 ? 1 : 0));

    Map<int, List<FlSpot>> accountData = {};
    for (var summary in _monthlySummaries) {
      if (!accountData.containsKey(summary.accountId)) {
        accountData[summary.accountId] = List.generate(12, (index) => FlSpot(index.toDouble(), 0.0));
      }
      int idx = last12Months.indexOf(summary.month);
      if (idx != -1 && last12Years[idx] == summary.year) {
        accountData[summary.accountId]![idx] = FlSpot(idx.toDouble(), summary.amount ?? 0.0);
      }
    }

    return accountData.entries.map((entry) {
      return LineChartBarData(
        spots: entry.value,
        isCurved: true,
        barWidth: 3,
        isStrokeCapRound: true,
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }
}
