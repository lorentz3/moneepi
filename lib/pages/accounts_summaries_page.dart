import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/account_dto.dart';
import 'package:myfinance2/dto/monthly_account_summary_dto.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/clean_service.dart';
import 'package:myfinance2/utils/color_identity.dart';
import 'package:myfinance2/services/app_config.dart';
import 'package:myfinance2/services/monthly_account_entity_service.dart';
import 'package:myfinance2/utils/graph_utils.dart';
import 'package:myfinance2/widgets/month_year_selector.dart';
import 'package:myfinance2/widgets/section_divider.dart';

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
  List<AccountDto> _accounts = [];
  String _currency = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadAllData();
    _setCurrency();
  }

  _setCurrency() async {
    final c = await AppConfig.instance.getCurrencySymbol();
    setState(() {
      _currency = c;
    });
  }

  _loadAllData() async {
    await CleanService.cleanTablesFromDeletedObjects();
    _accounts = await MonthlyAccountEntityService.getAllAccountsWithBalance();
    _monthlySummaries = await MonthlyAccountEntityService.getLast12MonthsAccountsSummaries(_selectedDate.month, _selectedDate.year);
    setState(() {});
  }

  _loadMonthlySummaries() async {
    _monthlySummaries = await MonthlyAccountEntityService.getLast12MonthsAccountsSummaries(_selectedDate.month, _selectedDate.year);
  }

  void _updateDate(DateTime newDate) async {
    _selectedDate = newDate;
    await _loadMonthlySummaries();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accounts summary")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SectionDivider(text: "Current balances"),
            _buildCurrentBalances(),
            SectionDivider(text: "Expenses"),
            _buildBalanceChart(TransactionType.EXPENSE),
            SectionDivider(text: "Incomes"),
            _buildBalanceChart(TransactionType.INCOME),
            SectionDivider(text: "Cumulative"),
            _buildCumulativeBalanceChart(),
            MonthYearSelector(selectedDate: _selectedDate, onDateChanged: _updateDate, alignment: MainAxisAlignment.center, enableFutureArrow: false,),
            SectionDivider(text: "Current month totals"),
            _buildMonthlySummary(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBalances() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: _accounts.asMap().entries.map((entry) {
            int index = entry.key;
            var account = entry.value;
            //Color rowColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;
            String accountTitle = account.icon != null ? "${account.icon} ${account.name}" : account.name;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 15,
                    child: Text(
                      accountTitle,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: getColor(index),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: Text(
                      account.balance < 0
                          ? ' - ${(- account.balance).toStringAsFixed(2)} $_currency'
                          : ' + ${account.balance.toStringAsFixed(2)} $_currency',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: account.balance < 0
                            ? Color.fromARGB(255, 206, 35, 23)
                            : Color.fromARGB(255, 33, 122, 34),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]
              )
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMonthlySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: _monthlySummaries.where((summary) => summary.month == _selectedDate.month && summary.year == _selectedDate.year).map((summary) {
            String accountTitle = summary.accountIcon != null ? "${summary.accountIcon} ${summary.accountName}" : summary.accountName;
            String expenseAmount = summary.expenseAmount != null ? summary.expenseAmount!.toStringAsFixed(2) : "0.00";
            String incomeAmount = summary.incomeAmount != null ? summary.incomeAmount!.toStringAsFixed(2) : "0.00";
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 10,
                    child: Text(
                      accountTitle,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(' - $expenseAmount $_currency',
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12, 
                        color: Color.fromARGB(255, 206, 35, 23),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(' + $incomeAmount $_currency',
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12, 
                        color: Color.fromARGB(255, 33, 122, 34),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]
              )
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBalanceChart(TransactionType type) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < 12) {
                          DateTime yearDate = DateTime(_selectedDate.year);
                          return (_selectedDate.month - 11 + index) == 1 ? Text(DateFormat('yyyy').format(yearDate), style: TextStyle(fontSize: 9)) : const Text("");
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(GraphUtils.formatThousandsTick(value), style: TextStyle(fontSize: 10)),
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
                          DateTime monthDate = DateTime(_selectedDate.year, _selectedDate.month - 11 + index);
                          return Text(DateFormat('MMM').format(monthDate), style: TextStyle(fontSize: 10));
                        }
                        return Text('');
                      },
                    ),
                  ),
                ),
                lineBarsData: _generateLineChartData(type),
                minY: 0,
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.blueGrey.shade100,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        final y = touchedSpot.y.toStringAsFixed(2);
                        final color = touchedSpot.bar.color;
                        return LineTooltipItem(
                          y,
                          TextStyle(
                            color: color, 
                            fontWeight: FontWeight.bold
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LineChartBarData> _generateLineChartData(TransactionType type) {
    List<int> last12Months = List.generate(12, (index) => (_selectedDate.month - 11 + index) > 0 ? _selectedDate.month - 11 + index : index + _selectedDate.month + 1);
    List<int> last12Years = List.generate(12, (index) => _selectedDate.year - (_selectedDate.month - 11 + index < 1 ? 1 : 0));
    Map<int, List<FlSpot>> accountData = {};
    for (var summary in _monthlySummaries) {
      if (!accountData.containsKey(summary.accountId)) {
        accountData[summary.accountId] = List.generate(12, (index) => FlSpot(index.toDouble(), 0.0));
      }
      int idx = last12Months.indexOf(summary.month);
      if (idx != -1 && last12Years[idx] == summary.year) {
        accountData[summary.accountId]![idx] = FlSpot(idx.toDouble(), type == TransactionType.EXPENSE ? summary.expenseAmount ?? 0.0 : summary.incomeAmount ?? 0.0);
      }
    }

    return accountData.entries.toList().asMap().entries.map((entry) {
      int colorIndex = entry.key; // 0, 1, 2, ...
      var accountEntry = entry.value;
      return LineChartBarData(
        spots: accountEntry.value,
        isCurved: false,
        barWidth: 3,
        isStrokeCapRound: true,
        color: getLightColor(colorIndex),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }
  
  Widget _buildCumulativeBalanceChart() {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < 12) {
                          DateTime yearDate = DateTime(_selectedDate.year);
                          return (_selectedDate.month - 11 + index) == 1 ? Text(DateFormat('yyyy').format(yearDate), style: TextStyle(fontSize: 9)) : const Text("");
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(GraphUtils.formatThousandsTick(value), style: TextStyle(fontSize: 10)),
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
                          DateTime monthDate = DateTime(_selectedDate.year, _selectedDate.month - 11 + index);
                          return Text(DateFormat('MMM').format(monthDate), style: TextStyle(fontSize: 10));
                        }
                        return Text('');
                      },
                    ),
                  ),
                ),
                lineBarsData: _generateLineChartDataCumulative(),
                //minY: 0,
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.blueGrey.shade100,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        final y = touchedSpot.y.toStringAsFixed(2);
                        final color = touchedSpot.bar.color;
                        return LineTooltipItem(
                          y,
                          TextStyle(
                            color: color, 
                            fontWeight: FontWeight.bold
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LineChartBarData> _generateLineChartDataCumulative() {
    // es: 3/2025
    // last12Months: 4 5 6 7 8 9 10 11 12 1 2 3
    // last12Years: 2024 2024 ... 2024 2025 2025 2025
    List<int> last12Months = List.generate(12, (index) => (_selectedDate.month - 11 + index) > 0 ? _selectedDate.month - 11 + index : index + _selectedDate.month + 1);
    List<int> last12Years = List.generate(12, (index) => _selectedDate.year - (_selectedDate.month - 11 + index < 1 ? 1 : 0));
    Map<int, List<FlSpot>> accountData = {};
    for (var summary in _monthlySummaries) {
      if (!accountData.containsKey(summary.accountId)) {
        accountData[summary.accountId] = List.generate(12, (index) => FlSpot(index.toDouble(), _getInitialBalance(summary.accountId) ?? 0.0));
      }
      int idx = last12Months.indexOf(summary.month);
      if (idx != -1 && last12Years[idx] == summary.year) {
        accountData[summary.accountId]![idx] = FlSpot(idx.toDouble(), summary.cumulativeBalance ?? 0.0);
      }
    }

    return accountData.entries.toList().asMap().entries.map((entry) {
      int colorIndex = entry.key; // 0, 1, 2, ...
      var accountEntry = entry.value;

      return LineChartBarData(
        spots: accountEntry.value,
        isCurved: false,
        barWidth: 3,
        isStrokeCapRound: true,
        color: getLightColor(colorIndex),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }
  
  double? _getInitialBalance(int accountId) {
    return _accounts.where((account) => account.id! == accountId).first.initialBalance;
  }
}
