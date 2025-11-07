import 'package:dio/dio.dart';
import '../models/experience.dart';

class ApiService {
  late final Dio _dio;
  // Base host used to normalize image/icon URLs returned as relative paths
  static const String _baseImageHost = 'https://staging.chamberofsecrets.8club.co';
  ApiService({Dio? dio}) {
    _dio = dio ?? Dio(BaseOptions(
      baseUrl: 'https://staging.chamberofsecrets.8club.co/v1/',
      connectTimeout: const Duration(seconds: 15),
    ));
  }

  Future<List<Experience>> fetchExperiences() async {
    final resp = await _dio.get('experiences?active=true');
    print('[API] Response status: ${resp.statusCode}');
    
    final list = <Experience>[];
    if (resp.statusCode == 200) {
      final data = resp.data as Map<String, dynamic>?;
      print('[API] Response data keys: ${data?.keys.toList()}');
      
      final experiences = data?['data']?['experiences'] as List<dynamic>?;
      print('[API] Number of experiences: ${experiences?.length ?? 0}');
      
      if (experiences != null) {
        for (final item in experiences) {
          final raw = item as Map<String, dynamic>;
          // normalize image/icon urls if API returns relative paths
          final normalized = Map<String, dynamic>.from(raw);
          final rawImage = (raw['image_url'] ?? '').toString();
          if (rawImage.isNotEmpty && !rawImage.startsWith('http')) {
            normalized['image_url'] = rawImage.startsWith('/') ? '$_baseImageHost$rawImage' : '$_baseImageHost/$rawImage';
          }
          final rawIcon = (raw['icon_url'] ?? '').toString();
          if (rawIcon.isNotEmpty && !rawIcon.startsWith('http')) {
            normalized['icon_url'] = rawIcon.startsWith('/') ? '$_baseImageHost$rawIcon' : '$_baseImageHost/$rawIcon';
          }
          final exp = Experience.fromJson(normalized);
          print('[API] Experience: ${exp.name} - Image URL: ${exp.imageUrl}');
          list.add(exp);
        }
      }
    }
    return list;
  }
}
