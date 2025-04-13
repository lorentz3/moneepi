import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthTotals extends StatelessWidget {
    final String currencySymbol;
    final DateTime selectedDate;
    final double totalExpense;
    final double totalIncome;
    final bool showMonth;

  const MonthTotals({
    super.key,
    required this.currencySymbol,
    required this.selectedDate,
    required this.totalExpense,
    required this.totalIncome,
    required this.showMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthString = showMonth ? DateFormat('MMMM yyyy').format(selectedDate) : DateFormat('yyyy').format(selectedDate) ;
    return Container(
        color: Colors.deepPurple[100],
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 18,
              child: Text(
                "$monthString totals: ",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 12,
              child: Text(
                " + ${totalIncome.toStringAsFixed(2)} $currencySymbol",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 66, 114, 68)),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 12,
              child: Text(
                " - ${totalExpense.toStringAsFixed(2)} $currencySymbol",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 150, 85, 80)
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