import 'package:flutter/material.dart';

class SaveButton extends StatelessWidget {
    final bool? isSaveEnabled;
    final VoidCallback onPressed;

  const SaveButton({
    super.key,
    this.isSaveEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    bool enabled = isSaveEnabled ?? true;
    return Padding(
      padding: EdgeInsets.only(left: 60, right: 60, bottom: 30, top: 5),
      child: ElevatedButton(
        onPressed: enabled
            ? onPressed
            : null, // disabilita il bottone
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? null : Colors.grey.shade400, // opzionale
        ),
        child: Text(
          'Save',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      ),
    );
  }
  
}