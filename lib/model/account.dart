class Account {
  final int? id;
  String? icon;
  String name;
  double initialBalance;
  int sort;

  Account({this.id, this.icon, required this.name, required this.initialBalance, required this.sort});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'icon': icon,
      'name': name,
      'initialBalance': initialBalance,
      'sort': sort
    };
  }

  Map<String, dynamic> toMapCreate() {
    return {
      'icon': icon,
      'name': name,
      'initialBalance': initialBalance,
    };
  }
  
  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'],
    icon: json['icon'], 
    name: json['name'], 
    initialBalance: json['initialBalance'],
    sort: json['sort'],
  );
}