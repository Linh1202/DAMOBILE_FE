/// Handler xử lý validate form trong ứng dụng
class ValidationHandler {
  /// Kiểm tra email có hợp lệ không
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Kiểm tra password có hợp lệ không (tối thiểu 6 ký tự)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Kiểm tra password và confirm password có khớp không
  static bool isPasswordMatch(String password, String confirmPassword) {
    return password == confirmPassword && password.isNotEmpty;
  }

  /// Kiểm tra họ tên có hợp lệ không
  static bool isValidName(String name) {
    return name.trim().isNotEmpty && name.length >= 2;
  }

  /// Kiểm tra mã OTP có đủ 6 số không (BE API yêu cầu len=6)
  static bool isValidOTP(String otp) {
    return otp.length == 6 && int.tryParse(otp) != null; // Đổi từ 4 -> 6
  }

  /// Trả về thông báo lỗi cho email
  static String? getEmailError(String email) {
    if (email.isEmpty) return "Vui lòng nhập email";
    if (!isValidEmail(email)) return "Email không hợp lệ";
    return null;
  }

  /// Trả về thông báo lỗi cho password
  static String? getPasswordError(String password) {
    if (password.isEmpty) return "Vui lòng nhập mật khẩu";
    if (!isValidPassword(password)) return "Mật khẩu phải có ít nhất 6 ký tự";
    return null;
  }

  /// Trả về thông báo lỗi cho confirm password
  static String? getConfirmPasswordError(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) return "Vui lòng xác nhận mật khẩu";
    if (!isPasswordMatch(password, confirmPassword)) return "Mật khẩu không khớp";
    return null;
  }

  /// Trả về thông báo lỗi cho họ tên
  static String? getNameError(String name) {
    if (name.trim().isEmpty) return "Vui lòng nhập họ và tên";
    if (!isValidName(name)) return "Họ và tên phải có ít nhất 2 ký tự";
    return null;
  }
}
