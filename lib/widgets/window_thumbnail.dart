import 'package:flutter/material.dart';
import '../models/window_node.dart';
import 'window_painter.dart';

class WindowThumbnail extends StatelessWidget {
  final WindowNode rootNode;
  final String name;
  final double widthMm;
  final double heightMm;

  const WindowThumbnail({
    super.key,
    required this.rootNode,
    required this.name,
    required this.widthMm,
    required this.heightMm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          // Çizim Alanı
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Minik ölçekleme hesabı
                  double scaleX = constraints.maxWidth / widthMm;
                  double scaleY = constraints.maxHeight / heightMm;
                  double scale = (scaleX < scaleY) ? scaleX : scaleY;

                  return CustomPaint(
                    painter: WindowPainter(rootNode: rootNode),
                    size: Size(widthMm * scale, heightMm * scale),
                  );
                },
              ),
            ),
          ),
          // Alt Bilgi Alanı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${widthMm.toInt()} x ${heightMm.toInt()} mm",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}