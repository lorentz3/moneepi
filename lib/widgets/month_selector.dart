import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged; // Callback per aggiornare la variabile

  const MonthSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  MonthSelectorState createState() => MonthSelectorState();
}

class MonthSelectorState extends State<MonthSelector> {

  void _changeMonth(int offset) {
    widget.onDateChanged(DateTime(widget.selectedDate.year, widget.selectedDate.month + offset, widget.selectedDate.day));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat('MMM').format(widget.selectedDate),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }
}