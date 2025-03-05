import 'package:myfinance2/model/transaction_type.dart';

class Category {
  final int? id;
  String? icon;
  String name;
  final TransactionType type;
  int sort;
  final int? parentId;
  double? monthThreshold;
  double? yearThreshold;

  Category({this.id, this.icon, required this.name, required this.type, required this.sort, this.parentId, this.monthThreshold, this.yearThreshold});

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'icon': icon,
      'name': name, 
      'type': type.name,
      'sort': sort, 
      'parentId': parentId, 
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
      'parentId': parentId, 
      'monthThreshold': monthThreshold,
      'yearThreshold': yearThreshold,
    };
  }
  
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    icon: json['icon'], 
    name: json['name'], 
    type: TransactionType.values.byName(json['type']),
    sort: json['sort'], 
    parentId: json['parentId'], 
    monthThreshold: json['monthThreshold'],
    yearThreshold: json['yearThreshold'],
  );
}