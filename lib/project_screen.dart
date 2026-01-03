import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/project.dart';
import '../widgets/window_painter.dart';
import '../models/window_node.dart';
import '../models/profile.dart'; // Profil modelini import et
import '../utils/utils.dart';

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

  // --- İŞLEM FONKSİYONLARI ---

  // 1. Bölme İşlemi
  Future<void> _handleSplit(int nodeId, bool isVertical) async {
    Navigator.pop(context); // Menüyü kapat
    
    // Yükleniyor...
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("İşleniyor..."), duration: Duration(milliseconds: 500)),
    );

    // API İsteği: Böl
    bool success = await _apiService.splitNode(nodeId, isVertical);

    if (success) {
      // YENİ: Fiyatı Hesaplat
      await _apiService.calculatePrice(widget.projectId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Başarıyla bölündü!"), backgroundColor: Colors.green),
      );
      _loadProject(); // Ekranı yenile
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hata oluştu"), backgroundColor: Colors.red),
      );
    }
  }

  // 2. Sadece Tip Değiştirme (Örn: Sabit Cam için)
  Future<void> _handleUpdateType(int nodeId, String type) async {
    Navigator.pop(context); // Menüyü kapat

    bool success = await _apiService.updateNodeType(nodeId, type);
    
    if (success) {
      // YENİ: Fiyatı Hesaplat (Cam m2 fiyatı eklendiğinde burası da hesaplanacak)
      await _apiService.calculatePrice(widget.projectId);
      _loadProject();
    }
  }

  // 3. Malzeme Seçim Dialogu (Profil Atama)
  void _showMaterialDialog(WindowNode node, String targetType) async {
    Navigator.pop(context); // Alttaki menüyü kapat
    
    // A. Önce Node Tipini Güncelle (Örn: EMPTY -> SASH)
    await _apiService.updateNodeType(node.id, targetType); 
    _loadProject(); // Çerçeveyi anlık göster

    // B. Uygun Profilleri Çek
    List<Profile> profiles = await _apiService.getProfilesByType(targetType); 

    if (!mounted) return;

    // C. Listeyi Göster
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$targetType Seçimi"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: profiles.isEmpty 
              ? const Center(child: Text("Uygun profil bulunamadı."))
              : ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.architecture, color: Colors.blueGrey),
                        title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${profile.code}\n${profile.pricePerMeter} TL/m"),
                        isThreeLine: true,
                        onTap: () async {
                          Navigator.pop(context); // Dialogu kapat
                          
                          // D. Seçilen Malzemeyi Ata
                          bool success = await _apiService.assignMaterial(node.id, profile.id, 'PROFILE');
                          
                          if (success) {
                            // YENİ: Fiyatı Hesaplat
                            await _apiService.calculatePrice(widget.projectId);
                            
                            _loadProject(); // Ekranı yenile
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("${profile.name} atandı!")),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
          ),
        );
      },
    );
  }

  // --- ARAYÜZ ---

  // Pencere Ekleme Dialogu
  void _showAddWindowDialog() {
    final nameController = TextEditingController();
    final widthController = TextEditingController();
    final heightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Pencere Oluştur"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Pencere Adı (Örn: Mutfak)"),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widthController,
                      decoration: const InputDecoration(labelText: "En (mm)"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: heightController,
                      decoration: const InputDecoration(labelText: "Boy (mm)"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || widthController.text.isEmpty || heightController.text.isEmpty) return;

                Navigator.pop(context); // Dialogu kapat

                // API İsteği
                bool success = await _apiService.addWindow(
                  widget.projectId,
                  nameController.text,
                  double.parse(widthController.text),
                  double.parse(heightController.text),
                );

                if (success) {
                  _loadProject(); // Ekranı yenile (Artık çizim gelecek!)
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pencere oluşturuldu!")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata oluştu")));
                }
              },
              child: const Text("Oluştur"),
            ),
          ],
        );
      },
    );
  }

  // Menüyü Göster
  void _showOptions(WindowNode node) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Parça Seçenekleri (ID: ${node.id})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                
                // --- BÖLME SEÇENEKLERİ ---
                const Align(alignment: Alignment.centerLeft, child: Text("Bölme İşlemleri", style: TextStyle(color: Colors.grey))),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(icon: Icons.splitscreen, label: "Dikey", color: Colors.blue, onTap: () => _handleSplit(node.id, true)),
                    _buildActionButton(icon: Icons.horizontal_split, label: "Yatay", color: Colors.orange, onTap: () => _handleSplit(node.id, false)),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // --- DOLDURMA SEÇENEKLERİ ---
                const Align(alignment: Alignment.centerLeft, child: Text("Atama İşlemleri", style: TextStyle(color: Colors.grey))),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Sabit Cam için basit tip değişimi kullanıyoruz
                    _buildActionButton(icon: Icons.crop_square, label: "Sabit Cam", color: Colors.lightBlue, onTap: () => _handleUpdateType(node.id, 'GLASS')),
                    // Kanat için Profil Seçimi kullanıyoruz
                    _buildActionButton(icon: Icons.window, label: "Kanat", color: Colors.redAccent, onTap: () => _showMaterialDialog(node, 'SASH')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // YENİ: Başlıkta Fiyat Gösterimi
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Çizim Masası", style: TextStyle(fontSize: 16)),
            FutureBuilder<Project?>(
              future: _projectFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(
                    "${snapshot.data!.totalPrice.toStringAsFixed(2)} TL", // FİYAT BURADA
                    style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                  );
                }
                return const SizedBox(); // Yüklenirken boş
              },
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _loadProject, icon: const Icon(Icons.refresh))
        ],
      ),
      // YENİ: Sağ alta ekleme butonu
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWindowDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<Project?>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Proje bulunamadı"));
          }

          final project = snapshot.data!;
          if (project.windowUnits.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.grid_off, size: 80, color: Colors.grey),
                   const SizedBox(height: 20),
                   const Text("Bu projede henüz pencere yok."),
                   const SizedBox(height: 20),
                   ElevatedButton.icon(
                     onPressed: _showAddWindowDialog, 
                     icon: const Icon(Icons.add),
                     label: const Text("İlk Pencereyi Ekle"),
                     style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                   )
                 ],
               ),
             );
          }
          
          final windowUnit = project.windowUnits.first;
          final rootNode = windowUnit.rootNode!;

          return LayoutBuilder(
            builder: (context, constraints) {
              double availableWidth = constraints.maxWidth * 0.95;
              double availableHeight = constraints.maxHeight * 0.75;

              double scaleX = availableWidth / rootNode.width;
              double scaleY = availableHeight / rootNode.height;
              double scale = (scaleX < scaleY) ? scaleX : scaleY;

              double drawWidth = rootNode.width * scale;
              double drawHeight = rootNode.height * scale;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(windowUnit.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    GestureDetector(
                      onTapUp: (details) {
                        Offset localTouch = details.localPosition;
                        WindowNode? clickedNode = findNodeAt(rootNode, localTouch, Offset.zero, scale);

                        if (clickedNode != null) {
                          // Menüyü açmak için şartlar:
                          // 1. Düğümün tipi 'EMPTY' (Boşluk) ise
                          // 2. VEYA Düğüm 'FRAME' (Kasa) ise ve henüz bölünmemişse (çocuğu yoksa)
                          bool canInteract = clickedNode.nodeType == 'EMPTY' || 
                                             (clickedNode.nodeType == 'FRAME' && clickedNode.children.isEmpty);

                          if (canInteract) {
                            _showOptions(clickedNode);
                          } else {
                            // Dolu veya bölünmüş parçaya tıklandı (İleride düzenleme eklenebilir)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Seçilen parça: ${clickedNode.nodeType}")),
                            );
                          }
                        }
                      },
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
                        child: CustomPaint(
                          painter: WindowPainter(rootNode: rootNode),
                          size: Size(drawWidth, drawHeight),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
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