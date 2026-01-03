import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/window_unit.dart';
import '../models/window_node.dart';
import '../models/profile.dart';
import '../widgets/window_painter.dart';
import '../utils/utils.dart';

class WindowEditorScreen extends StatefulWidget {
  final int projectId;
  final WindowUnit windowUnit; // Düzenlenecek pencere

  const WindowEditorScreen({
    super.key, 
    required this.projectId, 
    required this.windowUnit
  });

  @override
  State<WindowEditorScreen> createState() => _WindowEditorScreenState();
}

class _WindowEditorScreenState extends State<WindowEditorScreen> {
  final ApiService _apiService = ApiService();
  late WindowUnit currentUnit;
  late WindowNode rootNode;

  @override
  void initState() {
    super.initState();
    currentUnit = widget.windowUnit;
    rootNode = currentUnit.rootNode!;
    // Sayfa açıldığında veriyi tazelemeye gerek yok, parametre olarak geldi.
    // Ancak işlem yaptıkça güncelleyeceğiz.
  }

  // Sadece bu üniteyi yenilemek için (Backend'den tüm projeyi çekip filtreliyoruz)
  Future<void> _reloadUnit() async {
    final project = await _apiService.getProject(widget.projectId);
    if (project != null) {
      // Listeden güncel halini bul
      try {
        final updatedUnit = project.windowUnits.firstWhere((u) => u.id == widget.windowUnit.id);
        setState(() {
          currentUnit = updatedUnit;
          rootNode = updatedUnit.rootNode!;
        });
      } catch (e) {
        // Eğer silindiyse vs.
        print("Pencere bulunamadı: $e");
      }
    }
  }

  // --- İŞLEM FONKSİYONLARI ---
  
  Future<void> _handleSplit(int nodeId, bool isVertical) async {
    Navigator.pop(context);
    // Yükleniyor...
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İşleniyor..."), duration: Duration(milliseconds: 300)));
    
    bool success = await _apiService.splitNode(nodeId, isVertical);
    if (success) {
      await _apiService.calculatePrice(widget.projectId);
      await _reloadUnit(); // Ekranı tazele
    }
  }

  Future<void> _handleUpdateType(int nodeId, String type) async {
    Navigator.pop(context);
    bool success = await _apiService.updateNodeType(nodeId, type);
    if (success) {
      await _apiService.calculatePrice(widget.projectId);
      await _reloadUnit();
    }
  }

  void _showMaterialDialog(WindowNode node, String targetType) async {
    Navigator.pop(context);
    // Tip güncelle
    await _apiService.updateNodeType(node.id, targetType); 
    _reloadUnit(); // Kırmızı çerçeve gelsin
    
    // Profilleri çek
    List<Profile> profiles = await _apiService.getProfilesByType(targetType); 

    if (!mounted) return;
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
                return ListTile(
                  title: Text(profile.name),
                  subtitle: Text("${profile.pricePerMeter} TL/m"),
                  onTap: () async {
                    Navigator.pop(context);
                    bool success = await _apiService.assignMaterial(node.id, profile.id, 'PROFILE');
                    if (success) {
                      await _apiService.calculatePrice(widget.projectId);
                      _reloadUnit();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${profile.name} atandı!")));
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

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
                Text("Düzenle (ID: ${node.id})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                     _buildActionButton(Icons.splitscreen, "Dikey", Colors.blue, () => _handleSplit(node.id, true)),
                     _buildActionButton(Icons.horizontal_split, "Yatay", Colors.orange, () => _handleSplit(node.id, false)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.crop_square, "Sabit Cam", Colors.lightBlue, () => _handleUpdateType(node.id, 'GLASS')),
                    _buildActionButton(Icons.window, "Kanat", Colors.redAccent, () => _showMaterialDialog(node, 'SASH')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
      return Column(children: [
        InkWell(
          onTap: onTap, 
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            radius: 25, 
            backgroundColor: color.withOpacity(0.1), 
            child: Icon(icon, color: color)
          )
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500))
      ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(currentUnit.name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double availableWidth = constraints.maxWidth * 0.95;
          double availableHeight = constraints.maxHeight * 0.85;

          double scaleX = availableWidth / rootNode.width;
          double scaleY = availableHeight / rootNode.height;
          double scale = (scaleX < scaleY) ? scaleX : scaleY;

          return Center(
            child: GestureDetector(
               onTapUp: (details) {
                  WindowNode? clickedNode = findNodeAt(rootNode, details.localPosition, Offset.zero, scale);
                  if (clickedNode != null) {
                    // Boşluk veya Bölünmemiş Kasa ise menü aç
                    bool canInteract = clickedNode.nodeType == 'EMPTY' || (clickedNode.nodeType == 'FRAME' && clickedNode.children.isEmpty);
                    if (canInteract) _showOptions(clickedNode);
                  }
               },
               child: Container(
                 width: rootNode.width * scale,
                 height: rootNode.height * scale,
                 decoration: BoxDecoration(
                   color: Colors.white,
                   border: Border.all(color: Colors.grey.shade400),
                   boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
                 ),
                 child: CustomPaint(painter: WindowPainter(rootNode: rootNode)),
               ),
            ),
          );
        },
      ),
    );
  }
}
