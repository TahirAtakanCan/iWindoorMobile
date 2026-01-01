import 'window_unit.dart';

class Project {
  final int id;
  final String name;
  final String description;
  final List<WindowUnit> windowUnits;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.windowUnits,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    var list = json['windowUnits'] as List? ?? []; // Null gelirse boş liste
    List<WindowUnit> unitsList = list.map((i) => WindowUnit.fromJson(i)).toList();

    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      windowUnits: unitsList,
    );
  }
}