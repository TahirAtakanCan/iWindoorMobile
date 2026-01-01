import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/project.dart';
import '../widgets/window_painter.dart';
import '../models/window_node.dart';
import '../utils/utils.dart'; // findNodeAt fonksiyonunun burada olduğunu varsayıyoruz

class ProjectScreen extends StatefulWidget {
  final int projectId;
  const ProjectScreen({super.key, required this.projectId});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final ApiService _apiService = ApiService();
  late Future<Project?> _projectFuture;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  // Projeyi API'den çekme/yenileme fonksiyonu
  void _loadProject() {
    setState(() {
      _projectFuture = _apiService.getProject(widget.projectId);
    });
  }

  // Bölme İşlemi (API İsteği)
  Future<void> _handleSplit(int nodeId, bool isVertical) async {
    // Menüyü kapat
    Navigator.pop(context); 
    
    // Yükleniyor göstergesi (Opsiyonel ama iyi olur)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("İşleniyor..."), duration: Duration(milliseconds: 500)),
    );

    // API'ye istek at
    bool success = await _apiService.splitNode(nodeId, isVertical);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Başarıyla bölündü!"), backgroundColor: Colors.green),
      );
      // Ekranı yenile
      _loadProject();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bir hata oluştu"), backgroundColor: Colors.red),
      );
    }
  }

  // Alt Menüyü Göster
  void _showOptions(WindowNode node) {
    showModalBottomSheet(
      context: context,
      // isScrollControlled: true, // Eğer içerik çok uzunsa bunu açabilirsin
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea( // <--- EKLEME 1: Alt çentik (Home Indicator) payı bırakır
          child: Padding(
            padding: const EdgeInsets.all(20), // İç boşluk
            child: Column(
              mainAxisSize: MainAxisSize.min, // <--- EKLEME 2: İçerik kadar yer kapla (Sabit yükseklik yerine)
              children: [
                Text(
                  "Parça İşlemleri (ID: ${node.id})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Bu boşluğu nasıl bölmek istersiniz?", 
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.splitscreen, 
                      label: "Dikey Böl",
                      onTap: () => _handleSplit(node.id, true),
                      color: Colors.blue,
                    ),
                    _buildActionButton(
                      icon: Icons.horizontal_split,
                      label: "Yatay Böl",
                      onTap: () => _handleSplit(node.id, false),
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Alt tarafa biraz nefes payı
              ],
            ),
          ),
        );
      },
    );
  }

  // Menü butonu tasarım yardımcısı
  Widget _buildActionButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    required Color color
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(15),
          ),
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Çizim Masası"),
        actions: [
          IconButton(onPressed: _loadProject, icon: const Icon(Icons.refresh))
        ],
      ),
      body: FutureBuilder<Project?>(
        future: _projectFuture,
        builder: (context, snapshot) {
          // 1. Yükleniyor Durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          // 2. Hata Durumu
          else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          } 
          // 3. Veri Yok Durumu
          else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Proje bulunamadı"));
          }

          // 4. Veri Hazır
          final project = snapshot.data!;
          // Listeden ilk pencereyi alıyoruz (İleride Tabs yapabilirsin)
          if (project.windowUnits.isEmpty) {
             return const Center(child: Text("Bu projede hiç pencere yok."));
          }
          
          final windowUnit = project.windowUnits.first;
          final rootNode = windowUnit.rootNode!;

          // LayoutBuilder: Ekranın kalan boş alanını ölçer
          return LayoutBuilder(
            builder: (context, constraints) {
              
              // Ekranın %90 genişliğini ve %70 yüksekliğini çizim alanı yapalım
              double availableWidth = constraints.maxWidth * 0.95;
              double availableHeight = constraints.maxHeight * 0.75;

              // SCALE HESABI (En-boy oranını koruyarak sığdırma)
              double scaleX = availableWidth / rootNode.width;
              double scaleY = availableHeight / rootNode.height;
              // Hangi oran daha küçükse onu baz al (Sığdırma mantığı)
              double scale = (scaleX < scaleY) ? scaleX : scaleY;

              // Çizilecek alanın gerçek piksel boyutları
              double drawWidth = rootNode.width * scale;
              double drawHeight = rootNode.height * scale;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Başlık
                    Text(
                      windowUnit.name, 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 10),
                    
                    // --- ETKİLEŞİMLİ ÇİZİM ALANI ---
                    GestureDetector(
                      onTapUp: (details) {
                        // Tıklanan koordinat (Kutunun sol üstüne göre)
                        Offset localTouch = details.localPosition;
                        
                        // Hangi parçaya denk geldiğini bul (utils.dart)
                        WindowNode? clickedNode = findNodeAt(
                          rootNode, 
                          localTouch, 
                          Offset.zero, 
                          scale
                        );

                        if (clickedNode != null) {
                          // Sadece EMPTY (Boşluk) olanlara tıklanabilsin
                          if (clickedNode.nodeType == 'EMPTY') {
                             _showOptions(clickedNode);
                          } else {
                            // Dolu parçaya tıklandı (İleride silme/düzenleme eklenebilir)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Seçilen parça: ${clickedNode.nodeType}")),
                            );
                          }
                        }
                      },
                      // Container: Çizim alanı kadar yer kaplar
                      child: Container(
                        width: drawWidth,
                        height: drawHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        ),
                        // CustomPaint: Çizimi yapar
                        child: CustomPaint(
                          painter: WindowPainter(rootNode: rootNode),
                          size: Size(drawWidth, drawHeight),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Bilgi Alanı
                    Chip(
                      label: Text("Gerçek Boyut: ${rootNode.width.toStringAsFixed(0)} x ${rootNode.height.toStringAsFixed(0)} mm"),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}