import 'package:dio/dio.dart';
import '../models/project.dart';

class ApiService {
  // Android Emulator için: 10.0.2.2
  // iOS Simulator için: 127.0.0.1 veya localhost
  // Gerçek Cihaz için: Bilgisayarının IP adresi (örn: 192.168.1.35)
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.0.37:8080/api/v1', 
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<Project?> getProject(int id) async {
    try {
      final response = await _dio.get('/projects/$id');
      
      if (response.statusCode == 200) {
        return Project.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("API Hatası: $e");
      return null;
    }
  }

  // Node Bölme İsteği
  Future<bool> splitNode(int nodeId, bool isVertical) async {
    try {
      final response = await _dio.post(
        '/design/split/$nodeId',
        queryParameters: {'isVertical': isVertical},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print("Bölme Hatası: $e");
      return false;
    }
  }

}