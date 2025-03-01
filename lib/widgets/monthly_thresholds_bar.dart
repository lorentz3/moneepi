import 'package:flutter/material.dart';
import '../dto/monthly_category_transaction_summary_dto.dart';

class MonthlyThresholdsBar extends StatelessWidget {
  final MonthlyCategoryTransactionSummaryDto summary;

  const MonthlyThresholdsBar({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    double spent = summary.amount ?? 0.0;
    double threshold = summary.monthThreshold ?? 0.0;
    double percentage = 100 * ((threshold > 0) ? (spent / threshold).clamp(0.0, 10.99) : 0.0);
    Color progressColor = percentage > 75 ? (percentage > 89 ? Colors.red[300]! : Colors.orange[200]!) : Colors.green[300]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (100 - percentage).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  flex: percentage.toInt(),
                  child: SizedBox(),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3, // Permette alla categoria di adattarsi allo spazio disponibile
                    child: Text(
                      summary.categoryName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(
                    width: 60, // Fissa la larghezza della spesa
                    child: Text(
                      '${spent.toStringAsFixed(2)} €',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (100 - percentage) < 0 ? Colors.red : Colors.black),
                    ),
                  ),
                  SizedBox(width: 3),
                  SizedBox(
                    width: 60, // Fissa la larghezza della soglia
                    child: Text(
                      '/${threshold.toStringAsFixed(2)} €',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(100 - percentage).toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (100 - percentage) < 0 ? Colors.red : Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
