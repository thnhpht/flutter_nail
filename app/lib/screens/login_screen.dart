import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';
import '../generated/l10n/app_localizations.dart';

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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _userLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();
  final _shopEmailController = TextEditingController();
  final _employeePhoneController = TextEditingController();
  final _employeePasswordController = TextEditingController();

  bool _isLoading = false;
  bool _emailChecked = false;
  bool _emailExists = false;
  String _databaseName = '';
  String _currentStep =
      'role_selection'; // 'role_selection', 'email', 'login', 'create_account', 'employee_login'
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

  @override
  void dispose() {
    _emailController.dispose();
    _userLoginController.dispose();
    _passwordLoginController.dispose();
    _shopEmailController.dispose();
    _employeePhoneController.dispose();
    _employeePasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    final l10n = AppLocalizations.of(context)!;

    if (_emailController.text.trim().isEmpty) {
      AppWidgets.showFlushbar(context, l10n.pleaseEnterEmail,
          type: MessageType.warning);
      return;
    }

    if (!_emailController.text.contains('@')) {
      AppWidgets.showFlushbar(context, l10n.invalidEmail,
          type: MessageType.warning);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await widget.api.checkEmail(_emailController.text.trim());

      setState(() {
        _emailChecked = true;
        _emailExists = response.exists;
        if (response.exists) {
          _currentStep = 'login';
        } else {
          _currentStep = 'create_account';
        }
      });

      if (mounted) {
        if (response.exists) {
          AppWidgets.showFlushbar(
            context,
            '${l10n.welcomeBack}: ${_emailController.text.trim()}!',
            type: MessageType.success,
          );
        } else {
          AppWidgets.showFlushbar(context, response.message,
              type: MessageType.info);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getUserFriendlyErrorMessage(e.toString());
        AppWidgets.showFlushbar(context, errorMessage, type: MessageType.error);
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
          AppWidgets.showFlushbar(context, response.message,
              type: MessageType.success);
        }

        // Chuyển đến màn hình chính
        widget.onLoginSuccess();
      } else {
        if (mounted) {
          AppWidgets.showFlushbar(context, response.message,
              type: MessageType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getUserFriendlyErrorMessage(e.toString());
        AppWidgets.showFlushbar(context, errorMessage, type: MessageType.error);
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
      if (_currentStep == 'email' ||
          _currentStep == 'login' ||
          _currentStep == 'create_account') {
        _currentStep = 'role_selection';
      } else if (_currentStep == 'employee_login') {
        _currentStep = 'role_selection';
      } else {
        _currentStep = 'email';
      }
      _emailChecked = false;
      _emailExists = false;
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
          AppWidgets.showFlushbar(context, response.message,
              type: MessageType.success);
        }

        // Chuyển đến màn hình chính
        widget.onLoginSuccess();
      } else {
        if (mounted) {
          AppWidgets.showFlushbar(context, response.message,
              type: MessageType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = _getUserFriendlyErrorMessage(e.toString());
        AppWidgets.showFlushbar(context, errorMessage, type: MessageType.error);
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
    final l10n = AppLocalizations.of(context)!;
    // Chuyển đổi lỗi API thành thông báo thân thiện với người dùng
    if (error.contains('HTTP 400')) {
      if (error.contains('Mật khẩu không chính xác')) {
        return l10n.passwordIncorrect;
      } else if (error.contains('Thông tin đăng nhập database')) {
        return l10n.databaseLoginInfoIncorrect;
      } else if (error.contains('Tên đăng nhập database')) {
        return l10n.databaseUsernameIncorrect;
      } else if (error.contains('Mật khẩu database')) {
        return l10n.databasePasswordIncorrect;
      } else if (error.contains('Tạo tài khoản thành công')) {
        return l10n.accountCreatedButDatabaseError;
      } else if (error.contains('Mật khẩu database không đủ mạnh')) {
        return l10n.databasePasswordNotStrongEnough;
      }
      return l10n.loginInfoIncorrect;
    } else if (error.contains('HTTP 500')) {
      return l10n.systemErrorOccurred;
    } else if (error.contains('Connection refused') ||
        error.contains('Failed host lookup')) {
      return l10n.cannotConnectToServer;
    } else if (error.contains('Timeout')) {
      return l10n.connectionTimeout;
    } else if (error.contains('SocketException')) {
      return l10n.networkConnectionError;
    }

    // Nếu không nhận diện được lỗi cụ thể, trả về thông báo chung
    return l10n.errorOccurredPleaseTryAgain;
  }

  VoidCallback? _getActionButtonHandler() {
    switch (_currentStep) {
      case 'role_selection':
        return null; // No action button for role selection
      case 'email':
        return _checkEmail;
      case 'login':
      case 'create_account':
        return _handleLogin;
      case 'employee_login':
        return _handleEmployeeLogin;
      default:
        return null;
    }
  }

  String _getActionButtonText() {
    final l10n = AppLocalizations.of(context)!;
    switch (_currentStep) {
      case 'role_selection':
        return l10n.continueText;
      case 'email':
        return l10n.connect;
      case 'login':
        return l10n.loginButton;
      case 'create_account':
        return l10n.createAccount;
      case 'employee_login':
        return l10n.loginButton;
      default:
        return l10n.continueText;
    }
  }

  Widget _buildRoleSelection() {
    final l10n = AppLocalizations.of(context)!;
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
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedRole == 'shop_owner'
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: _selectedRole == 'shop_owner'
                          ? Colors.white
                          : Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.shopOwner,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedRole == 'shop_owner'
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.manageEntireSystem,
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedRole == 'shop_owner'
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedRole == 'shop_owner')
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 24),
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
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedRole == 'employee'
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: _selectedRole == 'employee'
                          ? Colors.white
                          : Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.employee,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedRole == 'employee'
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.accessServicesCreateOrdersAndBills,
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedRole == 'employee'
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedRole == 'employee')
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 24),
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
    final l10n = AppLocalizations.of(context)!;

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
                  _buildPlaceholderLogo(),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _currentStep == 'role_selection'
                        ? l10n.roleSelection
                        : _currentStep == 'email'
                            ? l10n.connect
                            : _currentStep == 'login'
                                ? l10n.login
                                : _currentStep == 'create_account'
                                    ? l10n.createAccount
                                    : l10n.employeeLogin,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _currentStep == 'role_selection'
                        ? l10n.selectAccountTypeToContinue
                        : _currentStep == 'email'
                            ? l10n.enterEmailToCheckAccount
                            : _currentStep == 'login'
                                ? l10n.enterPasswordToLogin
                                : _currentStep == 'create_account'
                                    ? _emailChecked && !_emailExists
                                        ? '${l10n.createNewAccountFor} $_databaseName'
                                        : l10n.createNewAccount
                                    : l10n.enterEmployeeLoginInfo,
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
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white70),
                        label: Text(l10n.cancel,
                            style: const TextStyle(color: Colors.white70)),
                      ),
                    ),

                  // Login Form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
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
                                labelText: l10n.shopEmail,
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.business,
                                    color: Colors.white70),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white30),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white30),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.pleaseEnterEmail;
                                }
                                if (!value.contains('@')) {
                                  return l10n.invalidEmail;
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
                                labelText: l10n.employeePhone,
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.phone,
                                    color: Colors.white70),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white30),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white30),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.pleaseEnterPhone;
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
                                labelText: l10n.employeePassword,
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.lock,
                                    color: Colors.white70),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white30),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white30),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.pleaseEnterPassword;
                                }
                                return null;
                              },
                            ),
                          ],

                          // Shop owner email field
                          if (_currentStep == 'email')
                            Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: l10n.email,
                                    labelStyle:
                                        const TextStyle(color: Colors.white70),
                                    prefixIcon: const Icon(Icons.email,
                                        color: Colors.white70),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Colors.white30),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Colors.white30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.pleaseEnterYourEmail;
                                    }
                                    if (!value.contains('@')) {
                                      return l10n.invalidEmailExample;
                                    }
                                    if (!value.contains('.')) {
                                      return l10n.invalidEmailMissingDomain;
                                    }
                                    return null;
                                  },
                                ),
                                // Show email check status
                                if (_emailChecked) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        _emailExists
                                            ? Icons.check_circle
                                            : Icons.info,
                                        color: _emailExists
                                            ? Colors.green
                                            : Colors.blue,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _emailExists
                                              ? l10n.emailExistsInSystem
                                              : l10n
                                                  .emailNotExistsWillCreateNew,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _emailExists
                                                ? Colors.green
                                                : Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                          // Database login fields (visible for shop owner login steps)
                          if (_currentStep == 'login' ||
                              _currentStep == 'create_account')
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _userLoginController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: l10n.username,
                                    labelStyle:
                                        const TextStyle(color: Colors.white70),
                                    prefixIcon: const Icon(Icons.person,
                                        color: Colors.white70),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Colors.white30),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Colors.white30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.pleaseEnterUsername;
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
                                    labelText: l10n.password,
                                    labelStyle:
                                        const TextStyle(color: Colors.white70),
                                    prefixIcon: const Icon(Icons.key,
                                        color: Colors.white70),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Colors.white30),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Colors.white30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.pleaseEnterPassword;
                                    }
                                    if (value.length < 8) {
                                      return l10n.passwordMinLength;
                                    }
                                    if (!value.contains(RegExp(r'[A-Z]'))) {
                                      return l10n.passwordMustHaveUppercase;
                                    }
                                    if (!value.contains(RegExp(r'[a-z]'))) {
                                      return l10n.passwordMustHaveLowercase;
                                    }
                                    if (!value.contains(RegExp(r'[0-9]'))) {
                                      return l10n.passwordMustHaveNumber;
                                    }
                                    if (!value.contains(RegExp(
                                        r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
                                      return l10n.passwordMustHaveSpecialChar;
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
                                onPressed: _isLoading
                                    ? null
                                    : _getActionButtonHandler(),
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF667eea)),
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

  Widget _buildPlaceholderLogo() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
