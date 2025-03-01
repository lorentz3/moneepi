import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myfinance2/dto/monthly_category_transaction_summary_dto.dart';

class CategoriesPieChart extends StatelessWidget {
  final List<MonthlyCategoryTransactionSummaryDto> monthCategoriesSummary; 
    final double pieHeight;

  const CategoriesPieChart({super.key, required this.monthCategoriesSummary, required this.pieHeight});


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: pieHeight,
      child: PieChart(
        PieChartData(
          sections: _generatePieSections(monthCategoriesSummary),
          centerSpaceRadius: 0,
          sectionsSpace: 1,
          startDegreeOffset: -90
        ),
      ),
    );
  }
  
  List<PieChartSectionData> _generatePieSections(List<MonthlyCategoryTransactionSummaryDto> monthCategoriesSummary) {
    final totalAmount = monthCategoriesSummary.fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));

    return monthCategoriesSummary.asMap().entries.map((entry) {
      var index = entry.key;
      var e = entry.value;
      final percentage = ((e.amount ?? 0.0) / totalAmount) * 100;
      return PieChartSectionData(
        color: _getColor(index),
        value: e.amount,
        title: percentage > 3 ? e.categoryName.split(" ")[0] : '',
        titlePositionPercentageOffset: 0.85,
        radius: 85,
        titleStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();
  }
  
  Color _getColor(int index) {
    final colors = [Colors.blue[900], Colors.purple[900], Colors.green[900], Colors.brown[700], Colors.red[900],
      Colors.orange[900], Colors.yellow[900], Colors.lime[900], Colors.pink[900],
      Colors.cyan[900], Colors.indigo[900], Colors.teal[900],];
      return colors[index % colors.length]!;
  }
}