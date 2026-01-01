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
    // mm cinsinden gelen ölçüleri ekran pikseline çevir
    double w = node.width * scale;
    double h = node.height * scale;

    // Çizilecek dikdörtgen (Rect)
    Rect rect = Rect.fromLTWH(origin.dx, origin.dy, w, h);

    // --- TİPE GÖRE ÇİZİM MANTIĞI ---
    Paint paint = Paint()..style = PaintingStyle.stroke;

    if (node.nodeType == 'FRAME') {
      // KASA: Kalın gri çerçeve
      paint.color = Colors.grey[800]!;
      paint.strokeWidth = 4.0;
      canvas.drawRect(rect, paint);
      
      // İçini hafif boyayalım (Opsiyonel)
      Paint fillPaint = Paint()..color = Colors.grey[300]!;
      canvas.drawRect(rect, fillPaint);
      
    } else if (node.nodeType == 'SASH') {
      // KANAT: Kırmızı ince çerçeve (Örnek)
      paint.color = Colors.red;
      paint.strokeWidth = 2.0;
      // Kanat kasadan biraz içeride olur (Offset mantığı ileride eklenecek)
      canvas.drawRect(rect, paint);
    } 
    // ... Diğer tipler (GLASS, MULLION) buraya eklenecek

    // --- KRİTİK NOKTA: ÇOCUKLARI ÇİZMEK (RECURSION) ---
    // Eğer bu parçanın çocukları varsa, onları da çizdirmeliyiz.
    // Şu an sadece tek parça (Root) olduğu için burası çalışmayacak ama 
    // altyapımız hazır olsun.
    
    /* double currentX = origin.dx;
    double currentY = origin.dy;
    
    for (var child in node.children) {
      _drawNode(canvas, child, Offset(currentX, currentY), scale);
      
      // Basit mantık: Yan yana dizildiğini varsayalım (İleride dikey/yatay ayrımı yapacağız)
      // currentX += child.width * scale; 
    }
    */
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Veri değişirse tekrar çiz
  }
}