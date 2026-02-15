import 'package:flutter/material.dart';
import 'package:myfinance2/utils/color_identity.dart';

class SectionDividerWithButton extends StatelessWidget {
  final String text;
  final String? description;
  final IconData? icon;
  final String? buttonText;
  final IconData? buttonIcon;
  final VoidCallback? onButtonPressed;
  
  const SectionDividerWithButton({
    super.key,
    required this.text,
    this.description,
    this.icon,
    this.buttonText,
    this.buttonIcon,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: lightPurpleBackground(),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: lightPurpleBorder(),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Optional icon
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: purpleText(),
            ),
            const SizedBox(width: 12),
          ],
          
          // Title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkPurpleText(),
                    letterSpacing: 0.2,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: purpleText(),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action button
          if (onButtonPressed != null)
            TextButton.icon(
              onPressed: onButtonPressed,
              icon: Icon(
                buttonIcon ?? Icons.add,
                size: 18,
              ),
              label: Text(
                buttonText ?? 'Add',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: purpleText(),
                backgroundColor: white(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: purpleBorder()),
                ),
              ),
            ),
        ],
      ),
    );
  }

}