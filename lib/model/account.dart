class Account {
  final int? id;
  String? icon;
  String name;
  final double balance;
  int sort;

  Account({this.id, this.icon, required this.name, required this.balance, required this.sort});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'icon': icon,
      'name': name,
      'balance': balance,
      'sort': sort
    };
  }

  Map<String, dynamic> toMapCreate() {
    return {
      'icon': icon,
      'name': name,
    };
  }
  
  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'],
    icon: json['icon'], 
    name: json['name'], 
    balance: json['balance'],
    sort: json['sort'],
  );
}