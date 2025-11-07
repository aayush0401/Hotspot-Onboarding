import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Provide ApiService via Riverpod so screens and services can reuse the instance.
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());