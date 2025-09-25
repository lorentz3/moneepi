import 'package:flutter/material.dart';
import 'package:myfinance2/utils/color_identity.dart';

class LeftToSpendRow extends StatelessWidget {
    final String currencySymbol;
    final double wantToSave;
    final double leftToSpend;

  const LeftToSpendRow({
    super.key,
    required this.wantToSave,
    required this.currencySymbol,
    required this.leftToSpend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple[100],
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Want to save: ",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.bold,
              color: Colors.black),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Expanded(
            child: Text(
              "${wantToSave.toStringAsFixed(2)} $currencySymbol",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                color: blue()
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: 5,),
          Text(
            "Left to spend: ",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.bold,
              color: Colors.black),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            "${leftToSpend.toStringAsFixed(2)} $currencySymbol",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold,
              color: leftToSpend > 0 ? blue() : red()
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(width: 15,)
        ],
      ),
    );
  }
  
}