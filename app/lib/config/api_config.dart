import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // URLs cho các platform khác nhau
  static const String androidEmulator = 'http://10.0.2.2:5088/api';
  static const String iosSimulator = 'http://192.168.1.154:5088/api';
  static const String androidDevice = 'http://192.168.1.12:5088/api';
  static const String iosDevice = 'http://172.20.10.2:5088/api';
  static const String web = 'http://localhost:5088/api';
  static const String desktop = 'http://localhost:5088/api';
  static const String fallback = 'http://192.168.1.154:5088/api';
  
  static String get baseUrl {
    // Kiểm tra environment variable trước
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Detect platform và trả về URL phù hợp
    if (kIsWeb) {
      return web;
    } else if (Platform.isAndroid) {
      // Kiểm tra xem có phải emulator không
      if (_isAndroidEmulator()) {
        return androidEmulator;
      } else {
        return androidDevice;
      }
    } else if (Platform.isIOS) {
      // Kiểm tra xem có phải simulator không
      if (_isIOSSimulator()) {
        return iosSimulator;
      } else {
        return iosDevice;
      }
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return desktop;
    }
    
    // Fallback
    return fallback;
  }
  
  // Helper methods để detect emulator/simulator
  static bool _isAndroidEmulator() {
    // Trong Android emulator, hostname thường là "android"
    try {
      final hostname = Platform.localHostname;
      return hostname.toLowerCase().contains('android') || 
             hostname.toLowerCase().contains('emulator');
    } catch (e) {
      return false;
    }
  }
  
  static bool _isIOSSimulator() {
    // Trong iOS simulator, có thể kiểm tra một số điều kiện
    try {
      final hostname = Platform.localHostname;
      return hostname.toLowerCase().contains('simulator') ||
             hostname.toLowerCase().contains('iphone') ||
             hostname.toLowerCase().contains('ipad');
    } catch (e) {
      return false;
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
      'isAndroidEmulator': Platform.isAndroid ? _isAndroidEmulator() : null,
      'isIOSSimulator': Platform.isIOS ? _isIOSSimulator() : null,
      'hostname': Platform.localHostname,
    };
  }
}
