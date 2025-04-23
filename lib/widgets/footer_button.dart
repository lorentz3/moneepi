import 'package:flutter/material.dart';

class FooterButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const FooterButton({super.key, required this.text, required this.onPressed, required this.color});

  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed, 
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: color,
            width: 3
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)
          )
        ),
        child: Text(
          text, 
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )
      )
    );
  }

}