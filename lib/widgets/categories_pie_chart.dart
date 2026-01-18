import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myfinance2/dto/monthly_category_transaction_summary_dto.dart';
import 'package:myfinance2/utils/color_identity.dart';

class CategoriesPieChart extends StatelessWidget {
  final List<MonthlyCategoryTransactionSummaryDto> monthCategoriesSummary; 
  final double pieHeight;
  final ValueChanged<MonthlyCategoryTransactionSummaryDto>? onCategoryTap;

  const CategoriesPieChart({
    super.key,
    required this.monthCategoriesSummary,
    required this.pieHeight,
    this.onCategoryTap,
  });


  @override
  Widget build(BuildContext context) {
    final filteredSummary = monthCategoriesSummary.where((e) => (e.amount ?? 0) > 0).toList();
    return SizedBox(
      height: pieHeight,
      child: PieChart(
        PieChartData(
          sections: _generatePieSections(filteredSummary),
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              // Only respond to tap up events to avoid double navigation
              if (event is! FlTapUpEvent) return;
              if (filteredSummary.isEmpty) return;
              final touchedSection = response?.touchedSection;
              if (touchedSection == null) return;
              final index = touchedSection.touchedSectionIndex;
              if (index < 0 || index >= filteredSummary.length) return;
              onCategoryTap?.call(filteredSummary[index]);
            },
          ),
          centerSpaceRadius: 0,
          sectionsSpace: 1,
          startDegreeOffset: -90
        ),
      ),
    );
  }
  
  List<PieChartSectionData> _generatePieSections(List<MonthlyCategoryTransactionSummaryDto> filteredSummary) {
    final totalAmount = filteredSummary.fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));
    if (totalAmount == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[400],
          value: 1,
          title: 'No transactions',
          radius: 85,
          titleStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ];
    }
    int slicesNumber = filteredSummary.length;
    return filteredSummary.asMap().entries.map((entry) {
      var index = entry.key;
      var e = entry.value;
      final percentage = ((e.amount ?? 0.0) / totalAmount) * 100;
      String title = e.categoryIcon != null ? e.categoryIcon! : e.categoryName[0];
      return PieChartSectionData(
        color: getColor(index),
        value: e.amount,
        title: percentage > 3 ? title : '',
        titlePositionPercentageOffset: _getTitlePositionPercentageOffset(slicesNumber, percentage),
        radius: 85,
        titleStyle: TextStyle(color: Colors.white, fontSize: _getTitleFontSize(slicesNumber, percentage), fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  double _getTitlePositionPercentageOffset(int slicesNumber, double percentage) {
    if (slicesNumber == 1) return 0;
    if (percentage > 40) return 0.5;
    if (percentage > 20) return 0.65;
    if (percentage > 10) return 0.7;
    if (percentage > 5) return 0.8;
    return 0.85;
  }
  
  double _getTitleFontSize(int slicesNumber, double percentage) {
    if (slicesNumber == 1) return 28;
    if (percentage > 40) return 28;
    if (percentage > 15) return 20;
    if (percentage > 5) return 16;
    return 14;
  }
}