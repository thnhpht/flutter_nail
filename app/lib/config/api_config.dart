import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL cho tất cả platform
  static const String _ApiServer = 'https://nailapi.logisticssoftware.vn/api';
  static const String _ApiLocal = 'http://localhost:5088/api';

  // Swagger URLs
  static const String _SwaggerServer =
      'https://nailapi.logisticssoftware.vn/swagger';
  static const String _SwaggerLocal = 'http://localhost:5088/swagger';

  static String get baseUrl {
    // Kiểm tra environment variable trước
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Trả về URL cố định
    return _ApiServer;
  }

  static String get swaggerUrl {
    // Kiểm tra environment variable trước
    const envUrl = String.fromEnvironment('SWAGGER_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Trả về Swagger URL dựa trên API URL hiện tại
    if (baseUrl.contains('localhost')) {
      return _SwaggerLocal;
    } else {
      return _SwaggerServer;
    }
  }

  // Helper method để debug platform info
  static String get platformInfo {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else if (Platform.isMacOS) {
      return 'macOS';
    }
    return 'Unknown';
  }

  // Debug method để kiểm tra cấu hình hiện tại
  static Map<String, dynamic> get debugInfo {
    return {
      'platform': platformInfo,
      'baseUrl': baseUrl,
      'swaggerUrl': swaggerUrl,
      'hostname': Platform.localHostname,
    };
  }
}
