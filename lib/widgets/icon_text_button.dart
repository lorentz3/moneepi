import 'package:flutter/material.dart';

class IconTextButton extends StatelessWidget {
  final Icon? icon;
  final String text;
  final VoidCallback onPressed;
  final Color? textColor;
  final Color? borderColor;
  final Color? backgroundColor;

  const IconTextButton({
    super.key, 
    required this.text, 
    required this.onPressed, 
    this.borderColor,
    this.icon,
    this.backgroundColor,
    this.textColor
  });

  
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed, 
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: borderColor ?? Colors.black87,
          width: 2
        ),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        ),
        padding: EdgeInsets.symmetric(horizontal: 10)
      ),
      child: Row(
        children: [
          icon ?? SizedBox(width: 0,),
          Text(
            text, 
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}