import 'package:myfinance2/model/account.dart';

class AccountDto {
  final int? id;
  String? icon;
  String name;
  final double balance;
  int sort;

  AccountDto({this.id, this.icon, required this.name, required this.balance, required this.sort});
  
  factory AccountDto.fromJson(Map<String, dynamic> json) => AccountDto(
    id: json['id'],
    icon: json['icon'], 
    name: json['name'], 
    balance: json['balance'],
    sort: json['sort'],
  );
  
  factory AccountDto.fromAccount(Account account, double balance) => AccountDto(
    id: account.id,
    icon: account.icon, 
    name: account.name, 
    balance: balance,
    sort: account.sort,
  );
}
