import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class YearSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged; // Callback per aggiornare la variabile
  final bool? enableFutureArrow;

  const YearSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.enableFutureArrow
  });

  @override
  YearSelectorState createState() => YearSelectorState();
}

class YearSelectorState extends State<YearSelector> {
  bool _enableFutureArrow = false;

  @override
  void initState() {
    super.initState();
    _enableFutureArrow = widget.enableFutureArrow ?? true;
  }

  void _changeYear(int offset) {
    widget.onDateChanged(DateTime(widget.selectedDate.year + offset, widget.selectedDate.month, widget.selectedDate.day));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeYear(-1),
          ),
          Text(
            DateFormat(' yyyy ').format(widget.selectedDate),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: (_enableFutureArrow || widget.selectedDate.year < DateTime.now().year) ? const Icon(Icons.chevron_right) : const Icon(Icons.block_rounded),
            onPressed: () => _enableFutureArrow || widget.selectedDate.year < DateTime.now().year ? _changeYear(1) : (),
          ),
        ],
      ),
    );
  }
}