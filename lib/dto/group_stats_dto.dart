import 'package:myfinance2/dto/category_summary_dto.dart';

class GroupStatsDto {
  final int? id;
  String? icon;
  String name;
  double? monthThreshold;
  double? totalExpense;
  List<CategorySummaryDto> categories;

  GroupStatsDto({this.id, this.icon, required this.name, this.monthThreshold, this.totalExpense, required this.categories});
  
  factory GroupStatsDto.fromJson(Map<String, dynamic> json, List<CategorySummaryDto> categories) => GroupStatsDto(
    id: json['groupId'],
    icon: json['groupIcon'], 
    name: json['groupName'], 
    monthThreshold: json['groupMonthThreshold'],
    totalExpense: json['totalExpense'],
    categories: categories,
  );
  
}
