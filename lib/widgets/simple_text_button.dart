import 'package:flutter/material.dart';
import 'package:chessjourney/utils/color_identity.dart';
import 'package:chessjourney/widgets/icon_text_button.dart';

class SimpleTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const SimpleTextButton({
    super.key, 
    required this.onPressed, 
    required this.text, 
    this.textColor, 
    this.backgroundColor, 
    this.borderColor
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: IconTextButton(
        onPressed: onPressed,
        text: text,
        textColor: textColor ?? deepPurple(),
        backgroundColor: backgroundColor ?? Colors.deepPurple[50],
        borderColor: borderColor ?? Colors.deepPurple[300],
      ),
    );
  }
  
}