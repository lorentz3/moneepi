import 'package:myfinance2/model/transaction_type.dart';

class Category {
  final int? id;
  String name;
  final TransactionType type;
  int sort;
  final int? parentId;
  final double? monthThreshold;
  final double? yearThreshold;

  Category({this.id, required this.name, required this.type, required this.sort, this.parentId, this.monthThreshold, this.yearThreshold});

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
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
    name: json['name'], 
    type: TransactionType.values.byName(json['type']),
    sort: json['sort'], 
    parentId: json['parentId'], 
    monthThreshold: json['monthThreshold'],
    yearThreshold: json['yearThreshold'],
  );
}