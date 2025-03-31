import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:myfinance2/dto/category_summary_dto.dart';
import 'package:myfinance2/dto/group_dto.dart';
import 'package:myfinance2/dto/group_stats_dto.dart';
import 'package:myfinance2/pages/group_form_page.dart';
import 'package:myfinance2/services/group_entity_service.dart';
import 'package:myfinance2/widgets/month_selector.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<GroupStatsDto> _groupStats = [];
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadStats();
  }

  Future<void> _loadStats() async {
    _groupStats = await GroupEntityService.getGroupStats(_selectedDate.month, _selectedDate.year);
    setState(() {});
  }

  void _navigateToEditGroup(GroupDto group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupFormPage(group: group)),
    ).then((_) => setState(() {
      _loadStats();
    }));
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
      appBar: AppBar(title: MonthSelector(selectedDate: _selectedDate, onDateChanged: _updateDate),),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _groupStats.map((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con data raggruppata
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
                    if (group.monthThreshold != null) Text(
                      " / € ${group.monthThreshold!.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 16.sp,),
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
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToEditGroup(GroupDto(name: "", sort: 1, categories: []));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getCategoryWidget(BuildContext context, CategorySummaryDto category, Color rowColor) {
    String categoryTitle = "${category.icon ?? ""} ${category.name}";
    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "      $categoryTitle",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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
          if (category.monthThreshold != null) Expanded(
            flex: 5,
            child: Text(
              "  / € ${(category.monthThreshold ?? 0.0).toStringAsFixed(2)}",
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 16.sp),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: 30,)
        ],
      ),
    );
  }
}