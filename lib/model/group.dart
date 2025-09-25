import 'package:myfinance2/dto/group_dto.dart';

class Group {
  final int? id;
  String? icon;
  String name;
  int sort;
  double? monthThreshold;
  double? yearThreshold;

  Group({this.id, this.icon, required this.name, required this.sort, this.monthThreshold, this.yearThreshold});

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'icon': icon,
      'name': name, 
      'sort': sort, 
      'monthThreshold': monthThreshold,
      'yearThreshold': yearThreshold,
    };
  }

  Map<String, dynamic> toMapCreate() {
    return {
      'icon': icon,
      'name': name,
      'sort': sort, 
      'monthThreshold': monthThreshold,
      'yearThreshold': yearThreshold,
    };
  }
  
  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'],
    icon: json['icon'], 
    name: json['name'], 
    sort: json['sort'], 
    monthThreshold: json['monthThreshold'],
    yearThreshold: json['yearThreshold'],
  );
  
  factory Group.fromDto(GroupDto groupDto) => Group(
    id: groupDto.id,
    icon: groupDto.icon, 
    name: groupDto.name,
    sort: groupDto.sort, 
    monthThreshold: groupDto.monthThreshold,
    yearThreshold: groupDto.yearThreshold,
  );
}