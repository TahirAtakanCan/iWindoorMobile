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

  // Fiyat Hesaplat
  Future<void> calculatePrice(int projectId) async {
    try {
      // DİKKAT: URL'in başındaki '/projects' kısmına ve {projectId}'ye dikkat et
      // Backend URL yapımız: /api/v1/projects/{id}/calculate-price
      // Dio BaseURL zaten /api/v1 ise, burası sadece /projects/... olmalı.
      
      await _dio.post('/projects/$projectId/calculate-price');
      
    } catch (e) {
      print("Fiyat Hesaplama Hatası: $e");
    }
  }

  // 1. Tüm Projeleri Çek
  Future<List<Project>> getAllProjects() async {
    try {
      final response = await _dio.get('/projects');
      if (response.statusCode == 200) {
        var list = response.data as List;
        return list.map((i) => Project.fromJson(i)).toList();
      }
      return [];
    } catch (e) {
      print("Proje Listesi Hatası: $e");
      return [];
    }
  }

  // 2. Yeni Proje Oluştur
  Future<Project?> createProject(String name, String description) async {
    try {
      final response = await _dio.post('/projects', data: {
        "name": name,
        "description": description,
        // Backend'de totalPrice ve windowUnits otomatik set ediliyor
      });
      
      if (response.statusCode == 200) {
        return Project.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Proje Oluşturma Hatası: $e");
      return null;
    }
  }

  // Pencere Ekle
  Future<bool> addWindow(int projectId, String name, double width, double height) async {
    try {
      await _dio.post('/projects/$projectId/windows', data: {
        "name": name,
        "width": width,
        "height": height
      });
      return true; // Başarılı
    } catch (e) {
      print("Pencere Ekleme Hatası: $e");
      return false;
    }
  }

  // Proje Güncelle
  Future<bool> updateProject(int id, String name, String description) async {
    try {
      final response = await _dio.put('/projects/$id', data: {
        "name": name,
        "description": description,
        // Backend entity yapısına göre diğer alanlar null gidebilir veya mevcut korunur
      });
      return response.statusCode == 200;
    } catch (e) {
      print("Güncelleme Hatası: $e");
      return false;
    }
  }

  // Proje Sil
  Future<bool> deleteProject(int id) async {
    try {
      final response = await _dio.delete('/projects/$id');
      return response.statusCode == 200;
    } catch (e) {
      print("Silme Hatası: $e");
      return false;
    }
  }

  Future<List<Profile>> getAllProfilesForConfig() async {
    try {
      // Önce Frame, sonra Sash, sonra Mullion çekip birleştirelim
      final frames = await getProfilesByType('FRAME');
      final sashes = await getProfilesByType('SASH');
      return [...frames, ...sashes];
    } catch (e) {
      return [];
    }
  }

  // Fiyat Güncelle
  Future<bool> updateProfilePrice(int id, double newPrice) async {
    try {
      // Query param olarak gönderiyoruz (?price=...)
      final response = await _dio.put('/catalog/profiles/$id/price', queryParameters: {
        "price": newPrice
      });
      return response.statusCode == 200;
    } catch (e) {
      print("Fiyat Güncelleme Hatası: $e");
      return false;
    }
  }

}