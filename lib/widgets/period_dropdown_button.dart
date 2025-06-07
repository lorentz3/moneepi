import 'package:flutter/material.dart';

enum PeriodOption { monthly, annually/*, period*/ }

extension PeriodOptionExtension on PeriodOption {
  String get label {
    switch (this) {
      case PeriodOption.monthly:
        return 'Monthly';
      case PeriodOption.annually:
        return 'Annually';
      /*case PeriodOption.period:
        return 'Period';*/
    }
  }
}

class PeriodDropdownButton extends StatefulWidget {
  final PeriodOption initialValue;
  final ValueChanged<PeriodOption>? onChanged;

  const PeriodDropdownButton({
    super.key,
    this.initialValue = PeriodOption.monthly,
    this.onChanged,
  });

  @override
  State<PeriodDropdownButton> createState() => _PeriodDropdownButtonState();
}

class _PeriodDropdownButtonState extends State<PeriodDropdownButton> {
  late PeriodOption _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1), // colore e spessore bordo
        borderRadius: BorderRadius.circular(4), // angoli arrotondati
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PeriodOption>(
          value: _selected,
          isDense: true,
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          dropdownColor: Theme.of(context).colorScheme.primaryContainer,
          style: const TextStyle(color: Colors.black),
          items: PeriodOption.values.map((PeriodOption option) {
            return DropdownMenuItem<PeriodOption>(
              value: option,
              child: Text(option.label),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selected = value;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(value);
              }
            }
          },
        ),
      ),
    );
  }
}
