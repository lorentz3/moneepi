import 'package:flutter/material.dart';

class MonthTotalsRow extends StatelessWidget {
  final String firstCellLabel;
  final String expenseColumn;
  final String incomeColumn;
  final String savedColumn;
  final Color? expenseColumnColor;
  final Color? incomeColumnColor;
  final Color? savedColumnColor;
  final Color? backgroundColor;

  const MonthTotalsRow({
    super.key,
    required this.firstCellLabel,
    required this.expenseColumn,
    required this.incomeColumn,
    required this.savedColumn,
    this.savedColumnColor,
    this.expenseColumnColor,
    this.incomeColumnColor,
    this.backgroundColor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            firstCellLabel,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold,
              color: Colors.black),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Expanded(
            child: Text(
              incomeColumn,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                color: incomeColumnColor ?? Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: Text(
              expenseColumn,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                color: expenseColumnColor ?? Colors.black87
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: Text(
              savedColumn,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                color: savedColumnColor ?? Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: 15,)
        ],
      ),
    );
  }
  
}