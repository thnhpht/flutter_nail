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
  final _shopEmailController = TextEditingController();
  final _employeePhoneController = TextEditingController();
  final _employeePasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailChecked = false;
  bool _emailExists = false;
  String _databaseName = '';
  String _currentStep = 'role_selection'; // 'role_selection', 'email', 'password', 'create_account', 'employee_login'
  String _selectedRole = 'shop_owner'; // 'shop_owner' or 'employee'

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final email = _emailController.text;
    if (email.contains('@')) {
      setState(() {
        _databaseName = email;
        // Tự động điền email vào trường tên đăng nhập database
        _userLoginController.text = email;
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
    _shopEmailController.dispose();
    _employeePhoneController.dispose();
    _employeePasswordController.dispose();
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
        await prefs.setString('user_role', response.userRole ?? 'shop_owner');

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

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'shop_owner') {
        _currentStep = 'email';
      } else {
        _currentStep = 'employee_login';
      }
    });
  }

  void _goBack() {
    setState(() {
      if (_currentStep == 'email' || _currentStep == 'password' || _currentStep == 'create_account') {
        _currentStep = 'role_selection';
      } else if (_currentStep == 'employee_login') {
        _currentStep = 'role_selection';
      } else {
        _currentStep = 'email';
      }
      _emailChecked = false;
      _emailExists = false;
      _passwordController.clear();
      _userLoginController.clear();
      _passwordLoginController.clear();
      _shopEmailController.clear();
      _employeePhoneController.clear();
      _employeePasswordController.clear();
      _databaseName = '';
    });
  }

  Future<void> _handleEmployeeLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = EmployeeLoginRequest(
        shopEmail: _shopEmailController.text.trim(),
        employeePhone: _employeePhoneController.text.trim(),
        employeePassword: _employeePasswordController.text,
      );

      final response = await widget.api.employeeLogin(request);
      
      if (response.success) {
        // Lưu thông tin đăng nhập
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', response.token);
        await prefs.setString('database_name', response.databaseName);
        await prefs.setString('user_role', response.userRole ?? 'employee');
        await prefs.setString('employee_id', response.employeeId ?? '');
        await prefs.setString('shop_email', _shopEmailController.text.trim());

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

  VoidCallback? _getActionButtonHandler() {
    switch (_currentStep) {
      case 'role_selection':
        return null; // No action button for role selection
      case 'email':
        return _checkEmail;
      case 'password':
      case 'create_account':
        return _handleLogin;
      case 'employee_login':
        return _handleEmployeeLogin;
      default:
        return null;
    }
  }

  String _getActionButtonText() {
    switch (_currentStep) {
      case 'role_selection':
        return 'Tiếp tục';
      case 'email':
        return 'Kết nối';
      case 'password':
        return 'Đăng nhập';
      case 'create_account':
        return 'Đăng ký';
      case 'employee_login':
        return 'Đăng nhập';
      default:
        return 'Tiếp tục';
    }
  }

  Widget _buildRoleSelection() {
    return Column(
      children: [
        // Shop Owner Option
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectRole('shop_owner'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedRole == 'shop_owner' 
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedRole == 'shop_owner' 
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: _selectedRole == 'shop_owner' ? Colors.white : Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chủ shop',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedRole == 'shop_owner' ? Colors.white : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quản lý toàn bộ hệ thống',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedRole == 'shop_owner' ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedRole == 'shop_owner')
                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Employee Option
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectRole('employee'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedRole == 'employee' 
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedRole == 'employee' 
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: _selectedRole == 'employee' ? Colors.white : Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhân viên',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedRole == 'employee' ? Colors.white : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Truy cập dịch vụ, tạo đơn và hóa đơn',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedRole == 'employee' ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedRole == 'employee')
                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ),

      ],
    );
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
                    'assets/icon/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    _currentStep == 'role_selection' ? 'Chọn loại tài khoản' :
                    _currentStep == 'email' ? 'Kết nối' : 
                    _currentStep == 'password' ? 'Đăng nhập' : 
                    _currentStep == 'create_account' ? 'Đăng ký' : 'Đăng nhập nhân viên',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    _currentStep == 'role_selection' ? 'Chọn loại tài khoản để tiếp tục' :
                    _currentStep == 'email' ? 'Nhập email để kiểm tra tài khoản' :
                    _currentStep == 'password' ? 'Nhập mật khẩu để đăng nhập' : 
                    _currentStep == 'create_account' ? 'Tạo tài khoản mới' : 'Nhập thông tin đăng nhập nhân viên',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Back button if not on first step
                  if (_currentStep != 'role_selection')
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
                          // Role selection
                          if (_currentStep == 'role_selection') ...[
                            _buildRoleSelection(),
                          ],

                          // Employee login form
                          if (_currentStep == 'employee_login') ...[
                            TextFormField(
                              controller: _shopEmailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email chủ shop',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.business, color: Colors.white70),
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
                                  return 'Vui lòng nhập email chủ shop';
                                }
                                if (!value.contains('@')) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _employeePhoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Số điện thoại nhân viên',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.phone, color: Colors.white70),
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
                                  return 'Vui lòng nhập số điện thoại';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _employeePasswordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu nhân viên',
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
                                return null;
                              },
                            ),
                          ],

                          // Shop owner email field
                          if (_currentStep == 'email')
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
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

                          // Password field (visible after email check for shop owner)
                          if (_currentStep == 'password' || _currentStep == 'create_account')
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

                          // Database login fields (visible for shop owner login steps)
                          if (_currentStep == 'password' || _currentStep == 'create_account')
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

                          // Action button (not shown for role selection)
                          if (_currentStep != 'role_selection')
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _getActionButtonHandler(),
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
                                        _getActionButtonText(),
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
