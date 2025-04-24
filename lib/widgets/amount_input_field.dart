import 'package:flutter/material.dart';

class AmountInputField extends StatefulWidget {
  final Function(double amount) onChanged;
  final double initialAmount;
  final String label;

  const AmountInputField({
    super.key,
    required this.onChanged,
    this.initialAmount = 0.0,
    required this.label,
  });

  @override
  State<AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  String _valueString = "";
  String _label = "";

  @override
  void initState() {
    super.initState();
    _valueString = widget.initialAmount > 0 ? widget.initialAmount.toStringAsFixed(2) : "";
    _label = widget.label;
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == '⌫') {
        if (_valueString.isNotEmpty) {
          _valueString = _valueString.substring(0, _valueString.length - 1);
        }
      } else if (key == ',') {
        if (!_valueString.contains(',')) {
          _valueString += ',';
        }
      } else {
        _valueString += key;
      }

      double parsed = double.tryParse(_valueString.replaceAll(',', '.')) ?? 0.0;
      widget.onChanged(parsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  _label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _valueString.isEmpty ? "0,00" : _valueString,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Keypad
        Expanded(
          flex: 3,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var key in ['1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '0', '⌫'])
                SizedBox(
                  width: 70,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _onKeyPressed(key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      key,
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
