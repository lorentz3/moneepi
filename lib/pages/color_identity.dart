  import 'package:flutter/material.dart';

final colors = [Colors.blue[900], Colors.purple[900], Colors.green[900], Colors.brown[700], Colors.red[900],
  Colors.orange[900], Colors.yellow[900], Colors.lime[900], Colors.pink[900],
  Colors.cyan[900], Colors.indigo[900], Colors.teal[900],];

Color getColor(int index) {
  return colors[index % colors.length]!;
}

final lightColors = [Colors.blue[500], Colors.purple[500], Colors.green[700], Colors.brown[500], Colors.red[500],
  Colors.orange[700], Colors.yellow[800], Colors.lime[700], Colors.pink[500],
  Colors.cyan[700], Colors.indigo[500], Colors.teal[500],];


Color getLightColor(int index) {
  return lightColors[index % colors.length]!;
}