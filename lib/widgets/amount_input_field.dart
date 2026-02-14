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
  late TextEditingController _controller;
  bool _showKeypad = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount > 0 ? widget.initialAmount.toStringAsFixed(2) : '',
    );
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0.0;
    widget.onChanged(parsed);
  }

  void _onKeypadPressed(String key) {
    if (key == '') {
      return;
    }
    if (key == '✓') {
      setState(() {
        _showKeypad = !_showKeypad;
      });
      return;
    }
    String text = _controller.text;

    if (key == '⌫') {
      if (text.isNotEmpty) {
        text = text.substring(0, text.length - 1);
      }
    } else if (key == '.' || key == ',') {
      if (!text.contains('.')) {
        text += '.';
      }
    } else {
      // Blocca a 2 cifre decimali
      if (text.contains('.')) {
        final parts = text.split('.');
        if (parts.length > 1 && parts[1].length >= 2) return;
      }
      text += key;
    }

    setState(() {
      _controller.text = text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padHorizontalPadding = 10;
    final double buttonSize = (screenWidth - (2 * padHorizontalPadding) - 50) / 4;
    debugPrint("screenWidth: $screenWidth, padHorizontalPadding: $padHorizontalPadding, buttonSize: $buttonSize");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text field with toggle button
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.label,
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_showKeypad ? Icons.keyboard_hide : Icons.keyboard),
              onPressed: () {
                setState(() {
                  _showKeypad = !_showKeypad;
                });
              },
            ),
          ],
        ),

        // Animated Keypad
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return SizeTransition(sizeFactor: animation, axisAlignment: -1.0, child: child);
          },
          child: _showKeypad
              ? Padding(
                  padding: EdgeInsets.only(top: 16, left: padHorizontalPadding, right: padHorizontalPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildKeypadRows(buttonSize),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  List<String> keys = ['1', '2', '3', '', '4', '5', '6', '', '7', '8', '9', '⌫', ',', '0', '.', '✓'];

  List<Row> _buildKeypadRows(double buttonSize) {
    List<Row> rows = [];
    final double height = buttonSize * 0.7;

    for (int i = 0; i < keys.length; i += 4) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int j = i; j < i + 4 && j < keys.length; j++)
              Padding(
                padding: const EdgeInsets.all(2),
                child: SizedBox(
                  width: buttonSize,
                  height: height,
                  child: ElevatedButton(
                    onPressed: () => _onKeypadPressed(keys[j]),
                    style: keys[j] != '' ? ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ) : ElevatedButton.styleFrom(
                      shadowColor: Colors.transparent, // rimuove l'ombra
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.transparent,
                    ) ,
                    child: Text(
                      keys[j],
                      style: TextStyle(fontSize: height * 0.4, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return rows;
  }
}
