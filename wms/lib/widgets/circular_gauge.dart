import 'package:flutter/material.dart';

class CircularGauge extends StatelessWidget {
  final double percentage;
  final String centerText;
  final String subtitle;
  final double size;
  

  final Color color; 

  const CircularGauge({
    super.key,
    required this.percentage,
    required this.centerText,
    this.subtitle = '',
    this.size = 150,
    this.color = Colors.teal, 
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: size * 0.12,
                color: Colors.grey.shade200,
              ),
              CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: size * 0.12,
                color: color, // Usa la variable color
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      centerText,
                      style: TextStyle(
                        fontSize: size * 0.22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (percentage >= 0)
                      Text(
                        "${percentage.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: size * 0.12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]
      ],
    );
  }
}