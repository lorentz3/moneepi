import 'package:myfinance2/model/category.dart';

class GroupDto {
  final int? id;
  String? icon;
  String name;
  int sort;
  double? monthThreshold;
  double? yearThreshold;
  List<Category>? categories;

  GroupDto({this.id, this.icon, required this.name, required this.sort, this.monthThreshold, this.yearThreshold, this.categories});
  
  factory GroupDto.fromJson(Map<String, dynamic> json) => GroupDto(
    id: json['id'],
    icon: json['icon'], 
    name: json['name'], 
    sort: json['sort'], 
    monthThreshold: json['monthThreshold'],
    yearThreshold: json['yearThreshold'],
  );
  
}
