import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class YearSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged; // Callback per aggiornare la variabile
  final MainAxisAlignment? alignment;
  final bool? enableFutureArrow;

  const YearSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.alignment,
    this.enableFutureArrow
  });

  @override
  YearSelectorState createState() => YearSelectorState();
}

class YearSelectorState extends State<YearSelector> {
  late DateTime _currentDate;
  MainAxisAlignment _alignment = MainAxisAlignment.start;
  bool _enableFutureArrow = false;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    if (widget.alignment != null) {
      _alignment = widget.alignment!;
    }
    _enableFutureArrow = widget.enableFutureArrow ?? true;
  }

  void _changeYear(int offset) {
    setState(() {
      _currentDate = DateTime(_currentDate.year + offset, _currentDate.month, 1);
    });
    widget.onDateChanged(_currentDate);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Row(
        mainAxisAlignment: _alignment,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeYear(-1),
          ),
          Text(
            DateFormat(' yyyy ').format(_currentDate),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: (_enableFutureArrow || _currentDate.year < DateTime.now().year) ? const Icon(Icons.chevron_right) : const Icon(Icons.block_rounded),
            onPressed: () => _enableFutureArrow || _currentDate.year < DateTime.now().year ? _changeYear(1) : (),
          ),
        ],
      ),
    );
  }
}