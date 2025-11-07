import 'package:dio/dio.dart';
import '../models/experience.dart';
import 'api_service.dart';

/// A small in-memory mock of ApiService for tests and local dev.
class MockApiService extends ApiService {
  MockApiService() : super(dio: Dio());

  @override
  Future<List<Experience>> fetchExperiences() async {
    // Return a small deterministic list for UI and tests
    await Future.delayed(const Duration(milliseconds: 50));
    return [
      Experience(id: 1, name: 'Dining', tagline: 'Home-cooked meals', description: 'Host meals and experiences', imageUrl: '', iconUrl: ''),
      Experience(id: 2, name: 'Guided Tours', tagline: 'Local tours', description: 'Show visitors around', imageUrl: '', iconUrl: ''),
      Experience(id: 3, name: 'Workshops', tagline: 'Teach a skill', description: 'Host a workshop', imageUrl: '', iconUrl: ''),
    ];
  }
}
