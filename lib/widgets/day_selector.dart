import 'package:flutter/material.dart';

class DaySelector extends StatefulWidget {
  final int selectedDay;
  final int month;
  final int year;
  final Function(int) onDayChanged; // Callback per aggiornare la variabile

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.month,
    required this.year,
    required this.onDayChanged,
  });

  @override
  DaySelectorState createState() => DaySelectorState();
}

class DaySelectorState extends State<DaySelector> {
  late int _currentDay;
  final MainAxisAlignment _alignment = MainAxisAlignment.start;

  @override
  void initState() {
    super.initState();
    _currentDay = widget.selectedDay;
  }

  Map<int, List<int>> calendar = {
    
  };

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day; // Restituisce l'ultimo giorno del mese
  }

  void _changeDay(int delta) {
    DateTime currentDate = DateTime(widget.year, widget.month, _currentDay);
    DateTime newDate = currentDate.add(Duration(days: delta));

    // Se il mese cambia, riportiamo al primo o all'ultimo giorno del mese corretto
    if (newDate.month != widget.month) {
      if (delta > 0) {
        newDate = DateTime(widget.year, widget.month + 1, 1);
      } else {
        newDate = DateTime(widget.year, widget.month, _daysInMonth(widget.year, widget.month));
      }
    }

    setState(() {
      _currentDay = newDate.day;
    });

    widget.onDayChanged(_currentDay);
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
            onPressed: () => _changeDay(-1),
          ),
          Text(
            "$_currentDay".padLeft(2, '0'),
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