class Configuration {
  final int? id;
  String name;
  int? intValue; //used also for booleans
  String? textValue;
  double? realValue;

  Configuration({this.id, required this.name, this.intValue, this.textValue, this.realValue});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'intValue': intValue,
      'textValue': textValue,
      'realValue': realValue,
    };
  }
  
  factory Configuration.fromJson(Map<String, dynamic> json) => Configuration(
    id: json['id'],
    name: json['name'], 
    intValue: json['intValue'], 
    textValue: json['textValue'], 
    realValue: json['realValue'], 
  );
}