import 'package:flutter/material.dart';
import 'package:myfinance2/utils/color_identity.dart';

class InfoLabel extends StatelessWidget {
  final String text;
  final double? fontSize;
  
  const InfoLabel({super.key, required this.text, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: blueGrey()),
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: backgroundLightBlue(),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: blue(),),
          SizedBox(width: 5,),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: fontSize ?? 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
}