import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../Utils/Constants/AppStrings.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;
  ApiService._internal();

  String get _baseUrl {
    final base = AppStrings.baseUrl;
    if (Platform.isAndroid) {
      if (base.contains('localhost')) return base.replaceFirst('localhost', '10.0.2.2');
      if (base.contains('127.0.0.1')) return base.replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return base;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<dynamic> get(String endpoint) async {
    String url = '$_baseUrl$endpoint';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw Exception("Không có kết nối internet: $e");
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    String url = '$_baseUrl$endpoint';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw Exception("Không có kết nối internet: $e");
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    String url = '$_baseUrl$endpoint';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw Exception("Không có kết nối internet: $e");
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }

  Future<dynamic> delete(String endpoint) async {
    String url = '$_baseUrl$endpoint';
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw Exception("Không có kết nối internet: $e");
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }

  dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(response.body);
      case 400:
        throw Exception("Yêu cầu không hợp lệ (400)");
      case 401:
        throw Exception("Không có quyền truy cập (401)");
      case 403:
        throw Exception("Bị từ chối truy cập (403)");
      case 404:
        throw Exception("Không tìm thấy tài nguyên (404)");
      case 500:
        throw Exception("Lỗi máy chủ nội bộ (500)");
      default:
        throw Exception("Lỗi không xác định: ${response.statusCode}");
    }
  }
}
