import 'package:flutter/material.dart';
import '../models/window_node.dart';

class WindowPainter extends CustomPainter {
  final WindowNode rootNode;

  WindowPainter({required this.rootNode});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. ÖLÇEKLEME (Scaling)
    // Backend'den gelen mm cinsinden (örn: 1200mm).
    // Ekranda sığdırmak için bir oran bulmalıyız.
    // Ekran genişliği / Pencere genişliği
    double scaleX = size.width / rootNode.width;
    double scaleY = size.height / rootNode.height;
    
    // En-boy oranını korumak için küçük olan oranı seçiyoruz
    double scale = (scaleX < scaleY) ? scaleX : scaleY;

    // Koordinat sistemini merkeze veya uygun yere taşımak istersen:
    // canvas.translate(offsetX, offsetY);

    // 2. RECURSIVE ÇİZİMİ BAŞLAT
    // Başlangıç noktası (0,0)
    _drawNode(canvas, rootNode, Offset.zero, scale);
  }

  void _drawNode(Canvas canvas, WindowNode node, Offset origin, double scale) {
    double w = node.width * scale;
    double h = node.height * scale;

    Rect rect = Rect.fromLTWH(origin.dx, origin.dy, w, h);
    Paint paint = Paint()..style = PaintingStyle.stroke;

    // --- TİP KONTROLLERİ ---
    if (node.nodeType == 'FRAME' || node.nodeType == 'MULLION_VERTICAL' || node.nodeType == 'MULLION_HORIZONTAL') {
      // Konteynerler için çerçeve
      paint.color = Colors.grey[800]!;
      paint.strokeWidth = 2.0;
      canvas.drawRect(rect, paint);
    } else if (node.nodeType == 'EMPTY') {
      // Boşluklar için kesikli çizgi veya daha silik bir renk
      paint.color = Colors.blueAccent.withOpacity(0.5);
      paint.strokeWidth = 1.0;
      // Boşluğun ortasına "Boş" yazısı veya simgesi bile koyabilirsin
      canvas.drawRect(rect, paint);
    }

    // --- RECURSIVE ÇOCUKLARI ÇİZME ---
    // Eğer çocukları varsa, onları doğru konuma yerleştirip çizdir
    if (node.children.isNotEmpty) {
      double currentX = origin.dx;
      double currentY = origin.dy;

      for (var child in node.children) {
        // Çocuğu çiz
        _drawNode(canvas, child, Offset(currentX, currentY), scale);

        // Bir sonraki çocuğun koordinatını hesapla
        if (node.nodeType == 'MULLION_VERTICAL') {
          // Dikey bölünmüşse, X ekseninde ilerle (Yanına çiz)
          currentX += child.width * scale;
        } else if (node.nodeType == 'MULLION_HORIZONTAL') {
          // Yatay bölünmüşse, Y ekseninde ilerle (Altına çiz)
          currentY += child.height * scale;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Veri değişirse tekrar çiz
  }
}