import 'package:flutter/material.dart';

class InventoryChart extends StatelessWidget {
  final int available;
  final int route;
  final int maintenance;
  final int damaged;
  final double size;

  const InventoryChart({
    super.key,
    required this.available,
    required this.route,
    required this.maintenance,
    required this.damaged,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final total = available + route + maintenance + damaged;
    

    if (total == 0) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: size * 0.1),
        ),
        child: Center(
          child: Text(
            "Sin datos",
            style: TextStyle(fontSize: size * 0.1, color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [

          CustomPaint(
            size: Size(size, size),
            painter: _ChartPainter(
              available: available,
              route: route,
              maintenance: maintenance,
              damaged: damaged,
              total: total,
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$total",
                  style: TextStyle(
                    fontSize: size * 0.25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Total Cajas",
                  style: TextStyle(
                    fontSize: size * 0.08,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


class _ChartPainter extends CustomPainter {
  final int available;
  final int route;
  final int maintenance;
  final int damaged;
  final int total;

  _ChartPainter({
    required this.available,
    required this.route,
    required this.maintenance,
    required this.damaged,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.13; 

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;


    double startAngle = -1.5708; 


    void drawSegment(int count, Color color) {
      if (count == 0) return;
      

      final sweepAngle = (count / total) * 2 * 3.14159;
      
      paint.color = color;
      

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle > 0.1 ? sweepAngle - 0.1 : sweepAngle, 
        false,
        paint,
      );
      

      startAngle += sweepAngle; 
    }


    drawSegment(available, Colors.teal);


    drawSegment(maintenance, Colors.amber.shade700);
    

    drawSegment(damaged, Colors.red);


  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}