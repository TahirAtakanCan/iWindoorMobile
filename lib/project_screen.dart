import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/project.dart';
import '../widgets/window_painter.dart';

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
    _projectFuture = _apiService.getProject(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Çizim Masası")),
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
          // Şimdilik projedeki İLK pencereyi alalım
          final windowUnit = project.windowUnits.first;
          final rootNode = windowUnit.rootNode!;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(windowUnit.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // --- ÇİZİM ALANI ---
                Container(
                  width: 300, // Ekranda ayırdığımız alan
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent), // Alanı görmek için sınır
                    color: Colors.white,
                  ),
                  child: CustomPaint(
                    painter: WindowPainter(rootNode: rootNode),
                    // Child boyutu painter'a constraints olarak gider
                  ),
                ),
                
                const SizedBox(height: 20),
                Text("Ölçü: ${rootNode.width} x ${rootNode.height} mm"),
              ],
            ),
          );
        },
      ),
    );
  }
}