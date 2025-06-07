import 'package:flutter/material.dart';

class SectionDivider extends StatelessWidget {
  final String text;  
  const SectionDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Divider(color: Colors.grey[400], thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.grey[400], thickness: 1),
          ),
        ],
      ),
    );
  }

}