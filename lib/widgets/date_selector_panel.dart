import 'package:flutter/material.dart';
import 'package:myfinance2/widgets/day_selector.dart';
import 'package:myfinance2/widgets/month_selector.dart';
import 'package:myfinance2/widgets/year_selector.dart';

class DateSelectorPanel extends StatefulWidget {
  final String label;
  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;

  const DateSelectorPanel({
    super.key,
    required this.label,
    required this.initialDate,
    required this.onChanged,
  });

  @override
  State<DateSelectorPanel> createState() => _DateSelectorPanelState();
}

class _DateSelectorPanelState extends State<DateSelectorPanel> {
  //late DateTime _selectedDate;

  /*@override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  void _updateDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    widget.onChanged(_selectedDate);
  }*/

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16
          ),
        ),
        DaySelector(
          selectedDate: widget.initialDate,
          onDateChanged: widget.onChanged,
        ),
        MonthSelector(
          selectedDate: widget.initialDate,
          onDateChanged: widget.onChanged,
        ),
        YearSelector(
          selectedDate: widget.initialDate,
          onDateChanged: widget.onChanged,
        ),
      ],
    );
  }
}
