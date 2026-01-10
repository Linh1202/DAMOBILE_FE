import 'dart:io';
import 'ApiService.dart';
import '../Utils/Constants/ApiEndpoints.dart';

class MediaService {
  static final MediaService instance = MediaService._internal();
  factory MediaService() => instance;
  MediaService._internal();

  final ApiService _apiService = ApiService.instance;

  Future<String> uploadMedia(File file) async {
    try {
      final response = await _apiService.postMultipartWithAuth(
        ApiEndpoints.uploadMedia,
        file.path,
        fieldName: 'file',
      );

      if (response['success'] == true && response['data'] != null) {
        return response['data']['url'] as String;
      } else {
        throw Exception(response['message'] ?? 'Upload failed');
      }
    } catch (e) {
      rethrow;
    }
  }
}
