import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:myfinance2/utils/date_utils.dart';

class MonthYearSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged; // Callback per aggiornare la variabile
  final MainAxisAlignment? alignment;
  final bool? enableFutureArrow;
  final bool? showYear;

  const MonthYearSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.alignment,
    this.enableFutureArrow,
    this.showYear,
  });

  @override
  MonthYearSelectorState createState() => MonthYearSelectorState();
}

class MonthYearSelectorState extends State<MonthYearSelector> {
  late DateTime _currentDate;
  MainAxisAlignment _alignment = MainAxisAlignment.start;
  bool _enableFutureArrow = false;
  bool _showYear = true;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    if (widget.alignment != null) {
      _alignment = widget.alignment!;
    }
    _enableFutureArrow = widget.enableFutureArrow ?? true;
    _showYear = widget.showYear ?? true;
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + offset, 1);
    });
    widget.onDateChanged(_currentDate);
  }

  Future<void> _pickMonthYear() async {
    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2200),
    );

    if (picked != null) {
      setState(() {
        if (!_enableFutureArrow && MyDateUtils.isFutureMonth(picked.month, picked.year)) {
          _currentDate = DateTime.now();
        } else {
          _currentDate = DateTime(picked.year, picked.month, 1);
        }
      });
      widget.onDateChanged(_currentDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Row(
        mainAxisAlignment: _alignment,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          GestureDetector(
            onTap: _pickMonthYear,
            child: Text(
              DateFormat(_showYear ? 'MMM yyyy' : 'MMM').format(_currentDate),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: (_enableFutureArrow || MyDateUtils.isPastMonth(_currentDate.month, _currentDate.year)) ? const Icon(Icons.chevron_right) : const Icon(Icons.block_rounded),
            onPressed: () => _enableFutureArrow || MyDateUtils.isPastMonth(_currentDate.month, _currentDate.year) ? _changeMonth(1) : (),
          ),
        ],
      ),
    );
  }
}