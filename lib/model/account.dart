class Account {
  final int? id;
  String name;
  final double balance;
  int sort;

  Account({this.id, required this.name, required this.balance, required this.sort});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'sort': sort
    };
  }

  Map<String, dynamic> toMapCreate() {
    return {'name': name};
  }
  
  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'],
    name: json['name'], 
    balance: json['balance'],
    sort: json['sort'],
  );
}