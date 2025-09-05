import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';
import '../api_client.dart';
import '../models.dart';

class LoginScreen extends StatefulWidget {
  final ApiClient api;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.api,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum MessageType { success, error, info, warning }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailChecked = false;
  bool _emailExists = false;
  String _databaseName = '';
  String _currentStep = 'email'; // 'email', 'password', 'create_account'

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final email = _emailController.text;
    if (email.contains('@')) {
      setState(() {
        _databaseName = email.replaceAll('@', '_').replaceAll('.', '_');
      });
    }
  }

  void showFlushbar(String message, {MessageType type = MessageType.info}) {
    Color backgroundColor;
    Icon icon;

    switch (type) {
      case MessageType.success:
        backgroundColor = Colors.green;
        icon = const Icon(Icons.check_circle, color: Colors.white);
        break;
      case MessageType.error:
        backgroundColor = Colors.red;
        icon = const Icon(Icons.error, color: Colors.white);
        break;
      case MessageType.warning:
        backgroundColor = Colors.orange;
        icon = const Icon(Icons.warning, color: Colors.white);
        break;
      case MessageType.info:
      default:
        backgroundColor = Colors.blue;
        icon = const Icon(Icons.info, color: Colors.white);
        break;
    }

    Flushbar(
      message: message,
      backgroundColor: backgroundColor,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      duration: const Duration(seconds: 3),
      messageColor: Colors.white,
      icon: icon,
    ).show(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _userLoginController.dispose();
    _passwordLoginController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    if (_emailController.text.trim().isEmpty) {
      showFlushbar('Vui lòng nhập email của bạn', type: MessageType.warning);
      return;
    }
    
    if (!_emailController.text.contains('@')) {
      showFlushbar('Vui lòng nhập email có định dạng hợp lệ (ví dụ: example@email.com)', type: MessageType.warning);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await widget.api.checkEmail(_emailController.text.trim());
      
      setState(() {
        _emailChecked = true;
        _emailExists = response.exists;
        if (response.exists) {
          _currentStep = 'password';
        } else {
          _currentStep = 'create_account';
        }
      });

      if (mounted) {
        showFlushbar(
          response.message,
          type: MessageType.info 
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getUserFriendlyErrorMessage(e.toString());
        showFlushbar(errorMessage, type: MessageType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userLogin: _userLoginController.text.trim(),
        passwordLogin: _passwordLoginController.text,
      );

      final response = await widget.api.login(request);
      
      if (response.success) {
        // Lưu thông tin đăng nhập
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', response.token);
        await prefs.setString('database_name', response.databaseName);
        await prefs.setString('user_email', _emailController.text.trim());
        await prefs.setString('user_login', _userLoginController.text.trim());
        await prefs.setString('password_login', _passwordLoginController.text);

        // Hiển thị thông báo thành công
        if (mounted) {
          showFlushbar(response.message, type: MessageType.success);
        }

        // Chuyển đến màn hình chính
        widget.onLoginSuccess();
      } else {
        if (mounted) {
          showFlushbar(response.message, type: MessageType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getUserFriendlyErrorMessage(e.toString());
        showFlushbar(errorMessage, type: MessageType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goBack() {
    setState(() {
      _currentStep = 'email';
      _emailChecked = false;
      _emailExists = false;
      _passwordController.clear();
      _userLoginController.clear();
      _passwordLoginController.clear();
    });
  }

  String _getUserFriendlyErrorMessage(String error) {
    // Chuyển đổi lỗi API thành thông báo thân thiện với người dùng
    if (error.contains('HTTP 400')) {
      if (error.contains('Mật khẩu không chính xác')) {
        return 'Mật khẩu không chính xác. Vui lòng kiểm tra lại.';
      } else if (error.contains('Thông tin đăng nhập database')) {
        return 'Thông tin đăng nhập database không chính xác. Vui lòng kiểm tra lại.';
      } else if (error.contains('Tên đăng nhập database')) {
        return 'Tên đăng nhập database không chính xác.';
      } else if (error.contains('Mật khẩu database')) {
        return 'Mật khẩu database không chính xác.';
      } else if (error.contains('Tạo tài khoản thành công')) {
        return 'Tạo tài khoản thành công nhưng không thể tạo database. Vui lòng liên hệ admin.';
      } else if (error.contains('Mật khẩu database không đủ mạnh')) {
        return 'Mật khẩu database không đủ mạnh. Vui lòng kiểm tra yêu cầu bên dưới.';
      }
      return 'Thông tin đăng nhập không chính xác. Vui lòng kiểm tra lại.';
    } else if (error.contains('HTTP 500')) {
      return 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.';
    } else if (error.contains('Connection refused') || error.contains('Failed host lookup')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
    } else if (error.contains('Timeout')) {
      return 'Kết nối bị timeout. Vui lòng thử lại.';
    } else if (error.contains('SocketException')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.';
    }
    
    // Nếu không nhận diện được lỗi cụ thể, trả về thông báo chung
    return 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'icon/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    _currentStep == 'email' ? 'Kết nối' : 
                    _currentStep == 'password' ? 'Đăng nhập' : 'Đăng ký',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    _currentStep == 'email' ? 'Nhập email để kiểm tra tài khoản' :
                    _currentStep == 'password' ? 'Nhập mật khẩu để đăng nhập' : 'Tạo tài khoản mới',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Back button if not on first step
                  if (_currentStep != 'email')
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        label: const Text('Quay lại', style: TextStyle(color: Colors.white70)),
                      ),
                    ),

                  // Login Form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email field (always visible)
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            enabled: _currentStep == 'email',
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.email, color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white30),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white30),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập email của bạn';
                              }
                              if (!value.contains('@')) {
                                return 'Email không hợp lệ (ví dụ: example@email.com)';
                              }
                              if (!value.contains('.')) {
                                return 'Email không hợp lệ (thiếu domain)';
                              }
                              return null;
                            },
                          ),

                          // Password field (visible after email check)
                          if (_currentStep != 'email')
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white30),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu';
                                    }
                                    if (value.length < 8) {
                                      return 'Mật khẩu phải có ít nhất 8 ký tự';
                                    }
                                    if (!value.contains(RegExp(r'[A-Z]'))) {
                                      return 'Mật khẩu phải có ít nhất 1 chữ hoa (A-Z)';
                                    }
                                    if (!value.contains(RegExp(r'[a-z]'))) {
                                      return 'Mật khẩu phải có ít nhất 1 chữ thường (a-z)';
                                    }
                                    if (!value.contains(RegExp(r'[0-9]'))) {
                                      return 'Mật khẩu phải có ít nhất 1 số (0-9)';
                                    }
                                    if (!value.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
                                      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),

                          // Database login fields (visible for all steps except email)
                          if (_currentStep != 'email')
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _userLoginController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Tên đăng nhập Database',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    prefixIcon: const Icon(Icons.person, color: Colors.white70),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white30),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập tên đăng nhập database';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordLoginController,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu Database',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    prefixIcon: const Icon(Icons.key, color: Colors.white70),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white30),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu database';
                                    }
                                    if (value.length < 8) {
                                      return 'Mật khẩu database phải có ít nhất 8 ký tự';
                                    }
                                    if (!value.contains(RegExp(r'[A-Z]'))) {
                                      return 'Mật khẩu database phải có ít nhất 1 chữ hoa (A-Z)';
                                    }
                                    if (!value.contains(RegExp(r'[a-z]'))) {
                                      return 'Mật khẩu database phải có ít nhất 1 chữ thường (a-z)';
                                    }
                                    if (!value.contains(RegExp(r'[0-9]'))) {
                                      return 'Mật khẩu database phải có ít nhất 1 số (0-9)';
                                    }
                                    if (!value.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
                                      return 'Mật khẩu database phải có ít nhất 1 ký tự đặc biệt';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),

                          const SizedBox(height: 24),

                          // Action button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : (_currentStep == 'email' ? _checkEmail : _handleLogin),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF667eea),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                                      ),
                                    )
                                  : Text(
                                      _currentStep == 'email' ? 'Kết nối' : 
                                      _currentStep == 'password' ? 'Đăng nhập' : 'Đăng ký',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
