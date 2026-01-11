import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../Utils/Constants/AppStrings.dart';
import 'AuthStorage.dart';

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

  Future<Map<String, String>> get _authHeaders async {
    final token = await AuthStorage.readToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

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

  Future<dynamic> getWithAuth(String endpoint) async {
    String url = '$_baseUrl$endpoint';
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw Exception("Không có kết nối internet: $e");
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }

  Future<dynamic> postWithAuth(String endpoint, Map<String, dynamic> data) async {
    String url = '$_baseUrl$endpoint';
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw Exception("Không có kết nối internet: $e");
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }

  Future<dynamic> putWithAuth(String endpoint, Map<String, dynamic> data) async {
    String url = '$_baseUrl$endpoint';
    try {
      final headers = await _authHeaders;
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw Exception("Không có kết nối internet: $e");
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }

  Future<dynamic> deleteWithAuth(String endpoint, [Map<String, dynamic>? data]) async {
    String url = '$_baseUrl$endpoint';
    try {
      final headers = await _authHeaders;
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw Exception("Không có kết nối internet: $e");
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }

  Future<dynamic> postMultipartWithAuth(String endpoint, String filePath, {String fieldName = 'file'}) async {
    String url = '$_baseUrl$endpoint';
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception("Kích thước tệp không được vượt quá 10MB");
      }

      final token = await AuthStorage.readToken();
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
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
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? "Yêu cầu không hợp lệ (400)");
      case 401:
        try {
          final body = jsonDecode(response.body);
          throw Exception(body['message'] ?? "Email hoặc mật khẩu không đúng.");
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception("Email hoặc mật khẩu không đúng.");
        }
      case 403:
        throw Exception("Bạn không có quyền thực hiện thao tác này.");
      case 404:
        throw Exception("Không tìm thấy tài nguyên (404)");
      case 500:
        try {
          final body = jsonDecode(response.body);
          throw Exception(body['message'] ?? "Lỗi máy chủ nội bộ (500)");
        } catch (e) {
          throw Exception("Lỗi máy chủ nội bộ (500): ${response.body}");
        }
      default:
        throw Exception("Lỗi không xác định: ${response.statusCode}");
    }
  }
}