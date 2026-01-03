import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/project.dart';
import 'window_editor_screen.dart'; // Az önce oluşturduğumuz ekran
import '../widgets/window_thumbnail.dart'; // Önizleme widget'ı

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Project?> _projectFuture;

  @override
  void initState() {
    super.initState();
    _refreshProject();
  }

  void _refreshProject() {
    setState(() {
      _projectFuture = _apiService.getProject(widget.projectId);
    });
  }

  // Yeni Pencere Ekleme Dialogu
  void _showAddWindowDialog() {
    final nameController = TextEditingController();
    final widthController = TextEditingController();
    final heightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Poz Ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController, 
                decoration: const InputDecoration(labelText: "Poz Adı (Örn: P-01)", hintText: "Salon Penceresi")
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: widthController, 
                    decoration: const InputDecoration(labelText: "En (mm)"), 
                    keyboardType: TextInputType.number
                  )
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: heightController, 
                    decoration: const InputDecoration(labelText: "Boy (mm)"), 
                    keyboardType: TextInputType.number
                  )
                ),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || widthController.text.isEmpty || heightController.text.isEmpty) return;
                
                Navigator.pop(context);
                
                await _apiService.addWindow(
                  widget.projectId,
                  nameController.text,
                  double.parse(widthController.text),
                  double.parse(heightController.text),
                );
                
                // Başarılı olursa listeyi yenile
                _refreshProject();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pencere eklendi!")));
              },
              child: const Text("Oluştur"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Proje İçeriği"),
        actions: [
           // Gelecek özellikler için placeholder butonlar
          IconButton(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf), tooltip: "PDF"),
          IconButton(onPressed: () {}, icon: const Icon(Icons.price_check), tooltip: "Maliyet"),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWindowDialog,
        icon: const Icon(Icons.add),
        label: const Text("Yeni Poz"),
      ),
      body: FutureBuilder<Project?>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Proje yüklenemedi."));
          }
          
          final project = snapshot.data!;
          final units = project.windowUnits;

          // Eğer hiç pencere yoksa
          if (units.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.grid_view, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text("Bu projede henüz pencere yok."),
                  const SizedBox(height: 10),
                  const Text("Sağ alttaki butondan ekleyebilirsin.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // ME03 TARZI GRID GÖRÜNÜMÜ
          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Yan yana 2 tane
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.85, // Kart oranı
            ),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              return GestureDetector(
                onTap: () async {
                  // Seçilen pencereyi düzenlemek için Editör'e git
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WindowEditorScreen(
                        projectId: project.id,
                        windowUnit: unit, // Sadece bu üniteyi gönder
                      ),
                    ),
                  );
                  // Dönüşte listeyi güncelle (Fiyat veya görünüm değişmiş olabilir)
                  _refreshProject();
                },
                child: WindowThumbnail(
                  rootNode: unit.rootNode!,
                  name: unit.name,
                  widthMm: unit.width,
                  heightMm: unit.height,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
