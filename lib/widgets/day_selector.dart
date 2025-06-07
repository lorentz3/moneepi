import 'package:flutter/material.dart';

class DaySelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged; // Callback per aggiornare la variabile

  const DaySelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  DaySelectorState createState() => DaySelectorState();
}

class DaySelectorState extends State<DaySelector> {

  void _changeDay(int offset) {
    final tentative = widget.selectedDate.add(Duration(days: offset));
    debugPrint("tentative=$tentative, currentDate=${widget.selectedDate}");

    if (tentative.month < widget.selectedDate.month) {
      // Se siamo usciti dal mese, torniamo all'ultimo giorno valido del mese
      final lastDayOfMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month + 1, 0);
      debugPrint("lastDayOfMonth=$lastDayOfMonth");
      widget.onDateChanged(lastDayOfMonth);
      return;
    }
        
    if (tentative.month > widget.selectedDate.month) {
      final firstDayOfMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
      debugPrint("firstDayOfMonth=$firstDayOfMonth");
      widget.onDateChanged(firstDayOfMonth);
      return;
    }
    widget.onDateChanged(tentative);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDay(-1),
          ),
          Text(
            "${widget.selectedDate.day}".padLeft(2, '0'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeDay(1),
          ),
        ],
      ),
    );
  }
}