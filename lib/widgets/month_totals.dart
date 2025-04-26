import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfinance2/utils/color_identity.dart';

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
    final balance = totalIncome - totalExpense;
    String monthTitle = DateFormat(" MMM ").format(selectedDate);
    return Container(
        color: Colors.deepPurple[100],
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              showMonth ? "$monthTitle Balance: " : "Balance: ",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: Colors.black),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(width: 5,),
            Expanded(
              child: Text(
                "${balance.toStringAsFixed(2)} $currencySymbol",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold,
                  color: balance >= 0 ? blue() : magenta()
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: 15,),
            Text(
              " + ${totalIncome.toStringAsFixed(2)} $currencySymbol",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 66, 114, 68)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(width: 15,),
            Text(
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
            SizedBox(width: 15,)
          ],
        ),
    );
  }
  
}