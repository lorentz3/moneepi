import 'package:flutter/material.dart';

class EmojiButton extends StatelessWidget {
    final String label;
    final String icon;
    final double width;
    final double height;
    final VoidCallback onPressed;
    final Color? backgroundColor;

  const EmojiButton({
    super.key,
    required this.label,
    required this.icon,
    required this.width,
    required this.height,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide.none,
          ),
          backgroundColor: backgroundColor,
          padding: EdgeInsets.zero,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double iconSize = constraints.maxHeight * 0.5; // % dell'altezza
            double labelSize = constraints.maxHeight * 0.16; // % dell'altezza
            
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0, // Leggera sovrapposizione
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: iconSize,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: constraints.maxHeight * 0.05, // Sovrappone leggermente l'icona
                  child: SizedBox(
                    width: constraints.maxWidth * 0.9,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: labelSize,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
}