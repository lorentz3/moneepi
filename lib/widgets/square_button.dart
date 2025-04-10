import 'package:flutter/material.dart';

class SquareButton extends StatelessWidget {
    final String label;
    final IconData icon;
    final double size;
    final bool? highlight;
    final String? highlightText;
    final VoidCallback onPressed;

  const SquareButton({
    super.key,
    required this.label,
    required this.icon,
    required this.size,
    this.highlight,
    this.highlightText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Permette al badge di uscire dai confini del bottone
      children: [
        SizedBox(
          width: size,
          height: size,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: highlight ?? false ? BorderSide(color: Colors.deepPurple, width: 2) : BorderSide.none,
              ),
              backgroundColor: Colors.deepPurple[100],
              padding: EdgeInsets.symmetric(vertical: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: size/2, color: Colors.black54),
                SizedBox(height: 1),
                if (label != "") Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5, 
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (highlight ?? false)
        Positioned(
          bottom: -10,
          left: 0,
          right: 0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double fontSize = 12;
              double maxWidth = constraints.maxWidth - 8; // Margine interno

              TextPainter textPainter = TextPainter(
                text: TextSpan(
                  text: highlightText,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                ),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              );

              // Riduciamo il font size finché il testo non rientra nel massimo spazio disponibile
              while (fontSize > 6) { 
                textPainter.text = TextSpan(
                  text: highlightText,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                );
                textPainter.layout();
                if (textPainter.width <= maxWidth) break;
                fontSize -= 1;
              }

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  highlightText ?? "",
                  style: TextStyle(fontSize: fontSize, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
}