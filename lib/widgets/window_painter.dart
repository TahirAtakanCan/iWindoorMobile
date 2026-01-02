import 'package:flutter/material.dart';
import '../models/window_node.dart';

class WindowPainter extends CustomPainter {
  final WindowNode rootNode;
  WindowPainter({required this.rootNode});

  @override
  void paint(Canvas canvas, Size size) {
    // Ölçekleme (Dışarıdan parametre almadığımız versiyon)
    double scaleX = size.width / rootNode.width;
    double scaleY = size.height / rootNode.height;
    double scale = (scaleX < scaleY) ? scaleX : scaleY;

    _drawNode(canvas, rootNode, Offset.zero, scale);
  }

  void _drawNode(Canvas canvas, WindowNode node, Offset origin, double scale) {
    double w = node.width * scale;
    double h = node.height * scale;
    Rect rect = Rect.fromLTWH(origin.dx, origin.dy, w, h);

    Paint paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black87
      ..strokeWidth = 2.0;

    // --- TİPE GÖRE ÇİZİM ---
    
    // 1. ÇERÇEVELER (KASA ve KAYITLAR)
    if (['FRAME', 'MULLION_VERTICAL', 'MULLION_HORIZONTAL'].contains(node.nodeType)) {
      paintStroke.color = Colors.grey[800]!;
      paintStroke.strokeWidth = 3.0;
      canvas.drawRect(rect, paintStroke);
    }
    
    // 2. SABİT CAM (GLASS)
    else if (node.nodeType == 'GLASS') {
      // Hafif mavi dolgu
      Paint paintFill = Paint()..color = Colors.lightBlue.withOpacity(0.2);
      canvas.drawRect(rect, paintFill);
      // Siyah ince çerçeve (Çıta)
      paintStroke.strokeWidth = 1.0;
      canvas.drawRect(rect, paintStroke);
    }

    // 3. AÇILIR KANAT (SASH)
    else if (node.nodeType == 'SASH') {
      // a) Kanat Profili (Dış çerçeveden biraz içeride olur)
      double sashInset = 10.0; // Ekranda 10 piksel içeride çiz
      Rect sashRect = rect.deflate(sashInset); // Dikdörtgeni küçült
      
      Paint sashPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.red[800]!
        ..strokeWidth = 3.0;
      
      canvas.drawRect(sashRect, sashPaint);

      // b) Açılım Üçgeni (Opening Triangle)
      // Bu üçgenin sivri ucu menteşenin olduğu yeri, geniş tarafı kolu gösterir.
      // Basit olması için "Sağ Açılım" çizelim ( < Şeklinde )
      
      Paint trianglePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.red
        ..strokeWidth = 1.0;
        // ..strokeCap = StrokeCap.round; // İsteğe bağlı kesikli çizgi yapılabilir

      Path path = Path();
      // Sağ kenarın ortası (Kol tarafı)
      path.moveTo(sashRect.right, sashRect.center.dy);
      // Sol üst köşe
      path.lineTo(sashRect.left, sashRect.top);
      // Tekrar sağ kenar (Kapatmak için değil, görsel üçgen için)
      path.moveTo(sashRect.right, sashRect.center.dy);
      // Sol alt köşe
      path.lineTo(sashRect.left, sashRect.bottom);
      
      canvas.drawPath(path, trianglePaint);
    }

    // 4. BOŞLUK (EMPTY)
    else if (node.nodeType == 'EMPTY') {
      // Seçilebilir olduğunu hissettirmek için ince gri çizgi
      paintStroke.color = Colors.grey[300]!;
      paintStroke.strokeWidth = 1.0;
      canvas.drawRect(rect, paintStroke);
      
      // Ortaya "+" işareti koyabiliriz (Opsiyonel)
    }

    // --- RECURSIVE ÇİZİM ---
    if (node.children.isNotEmpty) {
      double currentX = origin.dx;
      double currentY = origin.dy;

      for (var child in node.children) {
        _drawNode(canvas, child, Offset(currentX, currentY), scale);
        
        if (node.nodeType == 'MULLION_VERTICAL') {
          currentX += child.width * scale;
        } else if (node.nodeType == 'MULLION_HORIZONTAL') {
          currentY += child.height * scale;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}