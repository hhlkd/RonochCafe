import 'package:ronoch_coffee/models/image_model.dart';
import 'package:ronoch_coffee/services/mockapi_service.dart';

class ImageService {
  static Future<List<AppImage>> getImagesByType(String type) async {
    try {
      final allImages = await MockApiService.getImages();
      return allImages.where((img) => img.type == type).toList();
    } catch (e) {
      print('Error fetching images by type $type: $e');
      return [];
    }
  }

  static Future<AppImage?> getFirstImageByType(String type) async {
    try {
      final images = await getImagesByType(type);
      return images.isNotEmpty ? images.first : null;
    } catch (e) {
      print('Error getting first image by type $type: $e');
      return null;
    }
  }

  static Future<AppImage?> getImageById(String id) async {
    try {
      final allImages = await MockApiService.getImages();
      return allImages.firstWhere((img) => img.id == id);
    } catch (e) {
      print('Error getting image by id $id: $e');
      return null;
    }
  }

  static Future<List<AppImage>> getImagesByIds(List<String> ids) async {
    try {
      final allImages = await MockApiService.getImages();
      return allImages.where((img) => ids.contains(img.id)).toList();
    } catch (e) {
      print('Error getting images by ids: $e');
      return [];
    }
  }
}
