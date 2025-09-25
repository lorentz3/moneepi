import 'package:flutter/material.dart';
import 'package:myfinance2/dto/category_summary_dto.dart';
import 'package:myfinance2/dto/group_stats_dto.dart';
import 'package:myfinance2/dto/month_total_dto.dart';
import 'package:myfinance2/pages/category_stats_page.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/clean_service.dart';
import 'package:myfinance2/services/group_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/widgets/month_year_selector.dart';
import 'package:myfinance2/widgets/month_totals.dart';
import 'package:myfinance2/widgets/period_dropdown_button.dart';
import 'package:myfinance2/widgets/year_selector.dart';

class StatsPage extends StatefulWidget {
  final String currencySymbol;

  const StatsPage({super.key, required this.currencySymbol});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<GroupStatsDto> _groupStats = [];
  List<CategorySummaryDto> _categoryStats = [];
  late DateTime _selectedDate;
  bool _groupExists = false;
  double _otherCategoriesTotal = 0.0;
  late PeriodOption _periodOption;
  late String _currencySymbol;
  MonthTotalDto _monthTotalDto = MonthTotalDto(totalExpense: 0.0, totalIncome: 0.0);

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _periodOption = PeriodOption.monthly;
    _currencySymbol = widget.currencySymbol;
    _loadStats();
  }

  Future<void> _loadStats() async {
    await CleanService.cleanTablesFromDeletedObjects();
    _monthTotalDto = await TransactionEntityService.getMonthTotalDto(_periodOption == PeriodOption.monthly ? _selectedDate.month : null, _selectedDate.year);
    _groupStats = await GroupEntityService.getGroupStats(_periodOption == PeriodOption.monthly ? _selectedDate.month : null, _selectedDate.year);
    _groupExists = _groupStats.isNotEmpty;
    _categoryStats = await CategoryEntityService.getCategoriesWithoutGroup(_periodOption == PeriodOption.monthly ? _selectedDate.month : null, _selectedDate.year);
    _otherCategoriesTotal = _categoryStats.fold(0.0, (acc, cat) => acc + (cat.totalExpense ?? 0.0));
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: _getPeriodSelector(),
            ),
            PeriodDropdownButton(
              onChanged: (selectedOption) {
                if (selectedOption != _periodOption) {
                  setState(() {
                    _periodOption = selectedOption;
                    _loadStats();
                  });
                }
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MonthTotals(
                currencySymbol: _currencySymbol,
                selectedDate: _selectedDate, 
                totalExpense: _monthTotalDto.totalExpense, 
                totalIncome: _monthTotalDto.totalIncome,
                showMonth: _periodOption == PeriodOption.monthly,
              ),
              SizedBox(height: 5,),
              ..._groupStats.map((group) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header con gruppo
                    Container(
                      color: groupBgColor,
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                      child: Row(
                        children: [
                          Text(
                            "${group.icon ?? ""} ${group.name}",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 10,),
                          Text(
                            "Total: ${(group.totalExpense ?? 0.0).toStringAsFixed(2)} $_currencySymbol",
                            style: TextStyle(fontSize: 16,),
                          ),
                          if (_periodOption == PeriodOption.monthly && group.monthThreshold != null) Text(
                            " / ${group.monthThreshold!.toStringAsFixed(2)} $_currencySymbol",
                            style: TextStyle(fontSize: 12,),
                          ),
                        ],
                      ),
                    ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: group.categories.length,
                      itemBuilder: (context, index) {
                        CategorySummaryDto category = group.categories[index];
                        Color rowColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                        return _getCategoryWidget(context, category, rowColor);
                      },
                    ),
                  ],
                );
              }),
              // Lista senza raggruppamenti
              if (_categoryStats.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_groupExists) Container(
                      color: groupBgColor,
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                      child: Row(
                        children: [ 
                          Text(
                            "Other categories",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 10,),
                          Text(
                            "Total: ${_otherCategoriesTotal.toStringAsFixed(2)} $_currencySymbol",
                            style: TextStyle(fontSize: 14,),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _categoryStats.length,
                      itemBuilder: (context, index) {
                        CategorySummaryDto category = _categoryStats[index];
                        Color rowColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                        return _getCategoryWidget(context, category, rowColor);
                      },
                    ),
                  ],
                ),
            ]
          ),
        ),
      ),
    );
  }

  Widget _getCategoryWidget(BuildContext context, CategorySummaryDto category, Color rowColor) {
    String categoryTitle = "${category.icon ?? ""} ${category.name}";
    double totalExpense = category.totalExpense ?? 0.0;
    bool thresholdTrespassed = category.monthThreshold != null ? totalExpense > category.monthThreshold! : false;
    return GestureDetector(
      onTap: () => _navigateToCategoryStatsPage(category.id!),
      child: Container(
        color: rowColor,
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 12,
              child: Text(
                "   $categoryTitle",
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 9,
              child: Text(
                " ${(category.totalExpense ?? 0.0).toStringAsFixed(2)} $_currencySymbol ",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold,
                  color: thresholdTrespassed ? const Color.fromARGB(255, 129, 34, 27) : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  _getPeriodSelector() {
    if (_periodOption == PeriodOption.monthly){
      return MonthYearSelector(selectedDate: _selectedDate, onDateChanged: _updateDate, alignment: MainAxisAlignment.start,);
    }
    if (_periodOption == PeriodOption.annually){
      return YearSelector(selectedDate: _selectedDate, onDateChanged: _updateDate);
    }
  }
  
  _navigateToCategoryStatsPage(int categoryId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoryStatsPage(categoryId: categoryId, currencySymbol: _currencySymbol,)),
    );
  }
}