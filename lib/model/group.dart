import 'package:myfinance2/model/transaction_type.dart';

class Group {
  final int? id;
  String? icon;
  String name;
  final TransactionType type;
  int sort;
  double? monthThreshold;
  double? yearThreshold;

  Group({this.id, this.icon, required this.name, required this.type, required this.sort, this.monthThreshold, this.yearThreshold});

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
  
  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'],
    icon: json['icon'], 
    name: json['name'], 
    type: TransactionType.values.byName(json['type']),
    sort: json['sort'], 
    monthThreshold: json['monthThreshold'],
    yearThreshold: json['yearThreshold'],
  );
}