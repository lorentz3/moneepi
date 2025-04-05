import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:myfinance2/dto/category_summary_dto.dart';
import 'package:myfinance2/dto/group_stats_dto.dart';
import 'package:myfinance2/pages/category_stats_page.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/group_entity_service.dart';
import 'package:myfinance2/widgets/month_selector.dart';
import 'package:myfinance2/widgets/period_dropdown_button.dart';
import 'package:myfinance2/widgets/year_selector.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _periodOption = PeriodOption.monthly;
    _loadStats();
  }

  Future<void> _loadStats() async {
    _groupStats = await GroupEntityService.getGroupStats(_periodOption == PeriodOption.monthly ? _selectedDate.month : null, _selectedDate.year);
    _groupExists = _groupStats.isNotEmpty;
    _categoryStats = await CategoryEntityService.getCategoriesWithoutGroup(_selectedDate.month, _selectedDate.year);
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
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(),
            ),
            Expanded(
              flex: 3,
              child: Container(
                alignment: Alignment.center,
                child: _getPeriodSelector(),
              ),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 10,),
                        Text(
                          "Total: € ${(group.totalExpense ?? 0.0).toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 16.sp,),
                        ),
                        if (_periodOption == PeriodOption.monthly && group.monthThreshold != null) Text(
                          " / € ${group.monthThreshold!.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 12.sp,),
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
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 10,),
                        Text(
                          "Total: € ${_otherCategoriesTotal.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 14.sp,),
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
    );
  }

  Widget _getCategoryWidget(BuildContext context, CategorySummaryDto category, Color rowColor) {
    String categoryTitle = "${category.icon ?? ""} ${category.name}";
    return GestureDetector(
      onTap: () => _navigateToCategoryStatsPage(category.id!),
      child: Container(
        color: rowColor,
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 10,
              child: Text(
                "      $categoryTitle",
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 10,
              child: Text(
                " € ${(category.totalExpense ?? 0.0).toStringAsFixed(2)}",
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 3,
              child: _periodOption == PeriodOption.monthly && category.monthThreshold != null ? Text(
                "  / € ${(category.monthThreshold ?? 0.0).toStringAsFixed(2)}",
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 10.sp),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ) : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
  
  _getPeriodSelector() {
    if (_periodOption == PeriodOption.monthly){
      return MonthSelector(selectedDate: _selectedDate, onDateChanged: _updateDate);
    }
    if (_periodOption == PeriodOption.annually){
      return YearSelector(selectedDate: _selectedDate, onDateChanged: _updateDate);
    }
  }
  
  _navigateToCategoryStatsPage(int categoryId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoryStatsPage(categoryId: categoryId,)),
    );
  }
}