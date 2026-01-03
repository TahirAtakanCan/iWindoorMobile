import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/project.dart';
import 'window_editor_screen.dart';
import '../widgets/window_thumbnail.dart';

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
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Poz Adı")),
              Row(children: [
                Expanded(child: TextField(controller: widthController, decoration: const InputDecoration(labelText: "En"), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: heightController, decoration: const InputDecoration(labelText: "Boy"), keyboardType: TextInputType.number)),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                Navigator.pop(context);
                await _apiService.addWindow(
                  widget.projectId, nameController.text, 
                  double.parse(widthController.text), double.parse(heightController.text)
                );
                _refreshProject();
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
      appBar: AppBar(title: const Text("Proje İçeriği")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWindowDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<Project?>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final project = snapshot.data!;
          if (project.windowUnits.isEmpty) return const Center(child: Text("Henüz pencere yok."));

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 10, 
              mainAxisSpacing: 10, 
              childAspectRatio: 0.9, // Kart oranı
            ),
            itemCount: project.windowUnits.length,
            itemBuilder: (context, index) {
              final unit = project.windowUnits[index];
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (context) => WindowEditorScreen(projectId: project.id, windowUnit: unit),
                  ));
                  _refreshProject();
                },
                child: WindowThumbnail(
                  rootNode: unit.rootNode!, name: unit.name, 
                  widthMm: unit.width, heightMm: unit.height
                ),
              );
            },
          );
        },
      ),
    );
  }
}