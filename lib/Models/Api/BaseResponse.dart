/// Model BaseResponse - Response chung từ API
class BaseResponse {
  final bool success;
  final String message;

  BaseResponse({
    required this.success,
    this.message = '',
  });

  factory BaseResponse.fromJson(dynamic json) {
    final Map<String, dynamic> data = json is Map<String, dynamic> 
        ? json 
        : Map<String, dynamic>.from(json as Map);
    
    return BaseResponse(
      success: data['success'] ?? false,
      message: data['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}
