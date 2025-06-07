class CategorySummaryDto {
  final int? id;
  String? icon;
  String name;
  int sort;
  double? monthThreshold;
  double? totalExpense;

  CategorySummaryDto({this.id, this.icon, required this.name, required this.sort, this.monthThreshold, this.totalExpense});
  
  factory CategorySummaryDto.fromJson(Map<String, dynamic> json) => CategorySummaryDto(
    id: json['categoryId'],
    icon: json['categoryIcon'], 
    name: json['categoryName'], 
    sort: json['categorySort'], 
    monthThreshold: json['categoryMonthThreshold'],
    totalExpense: json['categoryTotalExpense'],
  );
  
}
