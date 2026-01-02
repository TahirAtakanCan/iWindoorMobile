import 'package:dio/dio.dart';
import 'package:iwindoor_mobil/models/profile.dart';
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

  // Tip Güncelleme İsteği
  Future<bool> updateNodeType(int nodeId, String type) async {
    try {
      final response = await _dio.post(
        '/design/update-type/$nodeId',
        queryParameters: {'type': type},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Tip Güncelleme Hatası: $e");
      return false;
    }
  }

  // Filtreli Profil Getir
  Future<List<Profile>> getProfilesByType(String type) async {
    try {
      final response = await _dio.get('/catalog/profiles/filter', queryParameters: {'type': type});
      if (response.statusCode == 200) {
        var list = response.data as List;
        return list.map((i) => Profile.fromJson(i)).toList();
      }
      return [];
    } catch (e) {
      print("Profil Çekme Hatası: $e");
      return [];
    }
  }

  // Malzeme Ata
  Future<bool> assignMaterial(int nodeId, int materialId, String type) async {
    try {
      await _dio.post('/design/assign-material/$nodeId', queryParameters: {
        'materialId': materialId,
        'type': type // 'PROFILE' veya 'GLASS'
      });
      return true;
    } catch (e) {
      return false;
    }
  }

}