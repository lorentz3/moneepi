import 'package:flutter/material.dart';
import 'package:myfinance2/utils/color_identity.dart';

class CircularAddButton extends StatelessWidget {
  final double size;
  final VoidCallback onPressed;

  const CircularAddButton({
    super.key,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final double circleSize = size * 0.5; // Smaller than emoji buttons
    
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: circleSize,
          height: circleSize,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: purpleBackground(),
              padding: EdgeInsets.zero,
            ),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: circleSize * 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
