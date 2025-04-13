import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/dto/category_summary_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/utils/graph_utils.dart';
import 'package:myfinance2/widgets/year_selector.dart';

class CategoryStatsPage extends StatefulWidget {
  final int categoryId;
  final String currencySymbol;

  const CategoryStatsPage({super.key, required this.categoryId, required this.currencySymbol});

  @override
  State<CategoryStatsPage> createState() => _CategoryStatsPageState();
}

class _CategoryStatsPageState extends State<CategoryStatsPage> {
  Map<int, CategorySummaryDto> _categoryStats = {};
  late DateTime _selectedDate;
  late int _categoryId;
  Category _category = Category(name: "Loading...", type: CategoryType.EXPENSE, sort: 1);
  double _total = 0;
  late String _currencySymbol;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _categoryId = widget.categoryId;
    _currencySymbol = widget.currencySymbol;
    _loadStats();
  }

  Future<void> _loadStats() async {
    _category = await CategoryEntityService.getCategoryById(_categoryId);
    _categoryStats = await CategoryEntityService.getCategoryStats(_categoryId, _selectedDate.year);
    if (_categoryStats.isNotEmpty) {
      _total = _categoryStats.values
        .map((e) => e.totalExpense ?? 0)
        .fold(0, (prev, amount) => prev + amount);
    }
    setState(() {});
  }

  void _updateDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final Color groupBgColor = Colors.blueGrey.shade100;
    final Color groupBgColor2 = Colors.blueGrey.shade200;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(),
            ),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.topLeft,
                child: YearSelector(selectedDate: _selectedDate, onDateChanged: _updateDate),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: groupBgColor,
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
              child: Row(
                children: [ 
                  Text(
                    "${_category.icon ?? ""} ${_category.name} ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            _buildBalanceChart(),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _categoryStats.length,
              itemBuilder: (context, index) {
                CategorySummaryDto category = _categoryStats[index + 1]!; //month 1 -> 12
                Color rowColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                return _getCategoryWidget(context, category, rowColor, index + 1);
              },
            ),
            SizedBox(height: 10,),
            Container(
              color: groupBgColor,
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
              child: Row(
                children: [ 
                  Text(
                    "    Total: ",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    "${_total.toStringAsFixed(2)} $_currencySymbol",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              color: groupBgColor2,
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
              child: Row(
                children: [ 
                  Text(
                    "    Average: ",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    " ${_monthlyAverage().toStringAsFixed(2)} $_currencySymbol",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_category.monthThreshold != null) Text(
                    " / ${_category.monthThreshold!.toStringAsFixed(2)} $_currencySymbol",
                    style: TextStyle(fontSize: 12,),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _monthlyAverage() {
    if (_selectedDate.year == DateTime.now().year) {
      return _total / _selectedDate.month;
    }
    return _total / 12;
  }

  Widget _getCategoryWidget(BuildContext context, CategorySummaryDto category, Color rowColor, int month) {
    DateTime dt = DateTime(_selectedDate.year, month, 1);
    String monthTitle = DateFormat(" MMM ").format(dt);
    double totalExpense = category.totalExpense ?? 0.0;
    bool thresholdExist = category.monthThreshold != null;
    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
            child: SizedBox(width: 50,)
          ),
          Expanded(
            flex: 5,
            child: Text(
              monthTitle,
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              " ${totalExpense.toStringAsFixed(2)} $_currencySymbol",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16, 
                color: thresholdExist && totalExpense > category.monthThreshold! ? const Color.fromARGB(255, 139, 33, 25) : Colors.black,
                fontWeight: FontWeight.bold
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            flex: 5,
            child: SizedBox(width: 50,)
          ),
        ],
      ),
    );
  }
  
  Widget _buildBalanceChart() {
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
                        if (index >= 0 && index <= 12) {
                          DateTime monthDate = DateTime(_selectedDate.year, index);
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
    );
  }

  List<LineChartBarData> _generateLineChartData() {
    Map<int, List<FlSpot>> data = {};
    if (_categoryStats.isEmpty) {
      return [];
    }
    for (int month = 1; month <= 12; ++month) {
      CategorySummaryDto summary = _categoryStats[month]!;
      if (!data.containsKey(0)) {
        data[0] = List.generate(12, (index) => FlSpot(index.toDouble(), 0.0));
      }
      data[0]![month - 1] = FlSpot(month.toDouble(), summary.totalExpense ?? 0.0);
    }
    if (_category.monthThreshold != null) {
      if (!data.containsKey(1)) {
        data[1] = [];
      }
      data[1]!.add(FlSpot(1.toDouble(), _category.monthThreshold!));
      data[1]!.add(FlSpot(12.toDouble(), _category.monthThreshold!));
    }

    return data.entries.map((entry) {
      return LineChartBarData(
        spots: entry.value,
        isCurved: false,
        barWidth: entry.key == 0 ? 3 : 1.5,
        isStrokeCapRound: true,
        dotData: FlDotData(show: entry.key == 0),
        color: entry.key == 0 ? const Color.fromARGB(255, 15, 82, 136) : Colors.red,
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }
}