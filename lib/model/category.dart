import 'package:myfinance2/model/category_type.dart';

class Category {
  final int? id;
  String? icon;
  String name;
  final CategoryType type;
  int sort;
  double? monthThreshold;
  double? yearThreshold;

  Category({this.id, this.icon, required this.name, required this.type, required this.sort, this.monthThreshold, this.yearThreshold});

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'icon': icon,
      'name': name, 
      'type': type.name,
      'sort': sort, 
      'monthThreshold': monthThreshold,
      'yearThreshold': yearThreshold,
    };
  }

  Map<String, dynamic> toMapCreate() {
    return {
      'icon': icon,
      'name': name,
      'type': type.name,
      'sort': sort, 
      'monthThreshold': monthThreshold,
      'yearThreshold': yearThreshold,
    };
  }
  
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    icon: json['icon'], 
    name: json['name'], 
    type: CategoryType.values.byName(json['type']),
    sort: json['sort'], 
    monthThreshold: json['monthThreshold'],
    yearThreshold: json['yearThreshold'],
  );
}