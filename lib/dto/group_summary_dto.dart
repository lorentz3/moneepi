class GroupSummaryDto {
  final int? id;
  String? icon;
  String name;
  int sort;
  double? monthThreshold;
  double? yearThreshold;
  double? totalExpense;
  List<GroupCategorySummaryDto> categories;

  GroupSummaryDto({this.id, this.icon, required this.name, required this.sort, this.monthThreshold, this.yearThreshold, this.totalExpense, required this.categories});
  
  factory GroupSummaryDto.fromJson(Map<String, dynamic> json) => GroupSummaryDto(
    id: json['id'],
    icon: json['icon'], 
    name: json['name'], 
    sort: json['sort'], 
    monthThreshold: json['monthThreshold'],
    yearThreshold: json['yearThreshold'],
    totalExpense: json['totalExpense'],
    categories: [],
  );
  
}

class GroupCategorySummaryDto {
  final int? id;
  String? icon;
  String name;
  int sort;
  double? totalExpense;

  GroupCategorySummaryDto({this.id, this.icon, required this.name, required this.sort, this.totalExpense});
}
