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
  final int? periodStartingDay;

  const MonthYearSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.alignment,
    this.enableFutureArrow,
    this.showYear,
    this.periodStartingDay,
  });

  @override
  MonthYearSelectorState createState() => MonthYearSelectorState();
}

class MonthYearSelectorState extends State<MonthYearSelector> {
  late DateTime _currentDate;
  MainAxisAlignment _alignment = MainAxisAlignment.center;
  bool _enableFutureArrow = false;
  bool _showYear = true;
  int _periodStartingDay = 1;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    if (widget.alignment != null) {
      _alignment = widget.alignment!;
    }
    _enableFutureArrow = widget.enableFutureArrow ?? true;
    _showYear = widget.showYear ?? true;
    _periodStartingDay = widget.periodStartingDay ?? 1;
  }

  @override
  void didUpdateWidget(MonthYearSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when widget properties change
    if (widget.selectedDate != oldWidget.selectedDate) {
      _currentDate = widget.selectedDate;
    }
    if (widget.alignment != oldWidget.alignment) {
      _alignment = widget.alignment ?? MainAxisAlignment.center;
    }
    if (widget.enableFutureArrow != oldWidget.enableFutureArrow) {
      _enableFutureArrow = widget.enableFutureArrow ?? true;
    }
    if (widget.showYear != oldWidget.showYear) {
      _showYear = widget.showYear ?? true;
    }
    if (widget.periodStartingDay != oldWidget.periodStartingDay) {
      _periodStartingDay = widget.periodStartingDay ?? 1;
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + offset, _currentDate.day);
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
          _currentDate = DateTime(picked.year, picked.month, _currentDate.day);
        }
      });
      widget.onDateChanged(_currentDate);
    }
  }

  String _getDisplayText() {
    if (_periodStartingDay == 1) {
      return DateFormat(_showYear ? 'MMM yyyy' : 'MMM').format(_currentDate);
    }
    if (_currentDate.day < _periodStartingDay) {
      DateTime tmp = DateTime(_currentDate.year, _currentDate.month - 1, _currentDate.day);
      return DateFormat(_showYear ? 'MMM yyyy' : 'MMM').format(tmp);
    }
    return DateFormat(_showYear ? 'MMM yyyy' : 'MMM').format(_currentDate);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: SizedBox(
        width: double.infinity, // forza la riga a occupare tutta la larghezza
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
                _getDisplayText(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: (_enableFutureArrow || MyDateUtils.isPastMonth(_currentDate.month, _currentDate.year)) ? const Icon(Icons.chevron_right) : const Icon(Icons.block_rounded),
              onPressed: () => _enableFutureArrow || MyDateUtils.isPastMonth(_currentDate.month, _currentDate.year) ? _changeMonth(1) : (),
            ),
          ],
        ),
      ),
    );
  }
}