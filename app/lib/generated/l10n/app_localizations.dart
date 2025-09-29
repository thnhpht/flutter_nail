import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('vi'),
    Locale('zh')
  ];

  /// The title of the application
  ///
  /// In vi, this message translates to:
  /// **'FShop'**
  String get appTitle;

  /// Salon name
  ///
  /// In vi, this message translates to:
  /// **'Salon'**
  String get salon;

  /// Today's overview
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan hôm nay'**
  String get todayOverview;

  /// Customers
  ///
  /// In vi, this message translates to:
  /// **'Khách hàng'**
  String get customers;

  /// Bills summary card title
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn'**
  String get bills;

  /// Revenue summary card title
  ///
  /// In vi, this message translates to:
  /// **'Doanh Thu'**
  String get revenue;

  /// Boss
  ///
  /// In vi, this message translates to:
  /// **'Boss'**
  String get boss;

  /// Employee
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên'**
  String get employee;

  /// Information section
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get information;

  /// Salon information
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get salonInfo;

  /// Menu
  ///
  /// In vi, this message translates to:
  /// **'Menu'**
  String get menu;

  /// Management section
  ///
  /// In vi, this message translates to:
  /// **'Quản lý'**
  String get management;

  /// Employees
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên'**
  String get employees;

  /// Categories
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get categories;

  /// Services section title
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ'**
  String get services;

  /// Create order button label
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn'**
  String get createOrder;

  /// Bills & Reports section
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn & Báo cáo'**
  String get billsReports;

  /// Reports
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get reports;

  /// Version
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản'**
  String get version;

  /// Logout
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// Loading
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// Cannot load version information
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin phiên bản'**
  String get cannotLoadVersionInfo;

  /// Login
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login;

  /// Username
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập'**
  String get username;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên đăng nhập'**
  String get pleaseEnterUsername;

  /// Password field label
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get password;

  /// Login button
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginButton;

  /// Login error
  ///
  /// In vi, this message translates to:
  /// **'Lỗi đăng nhập'**
  String get loginError;

  /// Invalid credentials message
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập hoặc mật khẩu không đúng'**
  String get invalidCredentials;

  /// Add
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get add;

  /// Edit
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get edit;

  /// Delete
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// Save button
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// Cancel button
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// Confirm
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// Search
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm'**
  String get search;

  /// Name
  ///
  /// In vi, this message translates to:
  /// **'Tên'**
  String get name;

  /// Phone number
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get phone;

  /// Address
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ'**
  String get address;

  /// Price
  ///
  /// In vi, this message translates to:
  /// **'Giá'**
  String get price;

  /// Description
  ///
  /// In vi, this message translates to:
  /// **'Mô tả'**
  String get description;

  /// Status
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get status;

  /// Date
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get date;

  /// Time
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get time;

  /// Total prefix
  ///
  /// In vi, this message translates to:
  /// **'Tổng'**
  String get total;

  /// Quantity
  ///
  /// In vi, this message translates to:
  /// **'Số lượng'**
  String get quantity;

  /// Unit price
  ///
  /// In vi, this message translates to:
  /// **'Đơn giá'**
  String get unitPrice;

  /// Language
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// Settings
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// Vietnamese language
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// English language
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Anh'**
  String get english;

  /// Chinese language
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Trung'**
  String get chinese;

  /// Korean language
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Hàn'**
  String get korean;

  /// Role selection title
  ///
  /// In vi, this message translates to:
  /// **'Chọn vai trò'**
  String get roleSelection;

  /// Shop owner
  ///
  /// In vi, this message translates to:
  /// **'Chủ salon'**
  String get shopOwner;

  /// Email field label
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get email;

  /// Check email
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra email'**
  String get checkEmail;

  /// Email exists
  ///
  /// In vi, this message translates to:
  /// **'Email đã tồn tại'**
  String get emailExists;

  /// Email not exists
  ///
  /// In vi, this message translates to:
  /// **'Email chưa tồn tại'**
  String get emailNotExists;

  /// Create account
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản'**
  String get createAccount;

  /// Employee login
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập nhân viên'**
  String get employeeLogin;

  /// Database name
  ///
  /// In vi, this message translates to:
  /// **'Tên database'**
  String get databaseName;

  /// Phone number label
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get phoneNumber;

  /// Employee phone field label
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại nhân viên'**
  String get employeePhone;

  /// Employee password field label
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu nhân viên'**
  String get employeePassword;

  /// Shop email field label
  ///
  /// In vi, this message translates to:
  /// **'Email Salon'**
  String get shopEmail;

  /// Please enter email validation message
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email'**
  String get pleaseEnterEmail;

  /// Please enter password validation message
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get pleaseEnterPassword;

  /// Please enter phone validation message
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số điện thoại'**
  String get pleaseEnterPhone;

  /// Please enter name
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên'**
  String get pleaseEnterName;

  /// Please enter database name
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên database'**
  String get pleaseEnterDatabaseName;

  /// Invalid email validation message
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ'**
  String get invalidEmail;

  /// Password too short
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 6 ký tự'**
  String get passwordTooShort;

  /// Phone too short
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại phải có ít nhất 10 số'**
  String get phoneTooShort;

  /// Database name too short
  ///
  /// In vi, this message translates to:
  /// **'Tên database phải có ít nhất 3 ký tự'**
  String get databaseNameTooShort;

  /// Checking email
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra email...'**
  String get checkingEmail;

  /// Creating account
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo tài khoản...'**
  String get creatingAccount;

  /// Logging in
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng nhập...'**
  String get loggingIn;

  /// Error checking email
  ///
  /// In vi, this message translates to:
  /// **'Lỗi kiểm tra email'**
  String get errorCheckingEmail;

  /// Error creating account
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tạo tài khoản'**
  String get errorCreatingAccount;

  /// Error logging in
  ///
  /// In vi, this message translates to:
  /// **'Lỗi đăng nhập'**
  String get errorLoggingIn;

  /// Account created successfully
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đã được tạo thành công'**
  String get accountCreatedSuccessfully;

  /// Login successful
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thành công'**
  String get loginSuccessful;

  /// Customer name label
  ///
  /// In vi, this message translates to:
  /// **'Tên khách hàng'**
  String get customerName;

  /// Customer phone
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại khách hàng'**
  String get customerPhone;

  /// Customer address
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ khách hàng'**
  String get customerAddress;

  /// Add customer
  ///
  /// In vi, this message translates to:
  /// **'Thêm khách hàng'**
  String get addCustomer;

  /// Edit customer
  ///
  /// In vi, this message translates to:
  /// **'Sửa khách hàng'**
  String get editCustomer;

  /// Delete customer
  ///
  /// In vi, this message translates to:
  /// **'Xóa khách hàng'**
  String get deleteCustomer;

  /// Customer added successfully
  ///
  /// In vi, this message translates to:
  /// **'Khách hàng đã được thêm thành công'**
  String get customerAddedSuccessfully;

  /// Customer updated successfully
  ///
  /// In vi, this message translates to:
  /// **'Khách hàng đã được cập nhật thành công'**
  String get customerUpdatedSuccessfully;

  /// Customer deleted successfully
  ///
  /// In vi, this message translates to:
  /// **'Xóa khách hàng thành công'**
  String get customerDeletedSuccessfully;

  /// Error adding customer
  ///
  /// In vi, this message translates to:
  /// **'Lỗi thêm khách hàng'**
  String get errorAddingCustomer;

  /// Error updating customer
  ///
  /// In vi, this message translates to:
  /// **'Lỗi cập nhật khách hàng'**
  String get errorUpdatingCustomer;

  /// Error deleting customer
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi xóa khách hàng'**
  String get errorDeletingCustomer;

  /// Confirm delete customer
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xóa khách hàng này?'**
  String get confirmDeleteCustomer;

  /// Employee name
  ///
  /// In vi, this message translates to:
  /// **'Tên nhân viên'**
  String get employeeName;

  /// Employee address
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ nhân viên'**
  String get employeeAddress;

  /// Employee position
  ///
  /// In vi, this message translates to:
  /// **'Chức vụ'**
  String get employeePosition;

  /// Employee salary
  ///
  /// In vi, this message translates to:
  /// **'Lương'**
  String get employeeSalary;

  /// Add employee
  ///
  /// In vi, this message translates to:
  /// **'Thêm nhân viên'**
  String get addEmployee;

  /// Edit employee
  ///
  /// In vi, this message translates to:
  /// **'Sửa nhân viên'**
  String get editEmployee;

  /// Delete employee
  ///
  /// In vi, this message translates to:
  /// **'Xóa nhân viên'**
  String get deleteEmployee;

  /// Employee added successfully
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên đã được thêm thành công'**
  String get employeeAddedSuccessfully;

  /// Employee updated successfully
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên đã được cập nhật thành công'**
  String get employeeUpdatedSuccessfully;

  /// Employee deleted successfully
  ///
  /// In vi, this message translates to:
  /// **'Xóa nhân viên thành công'**
  String get employeeDeletedSuccessfully;

  /// Error adding employee
  ///
  /// In vi, this message translates to:
  /// **'Lỗi thêm nhân viên'**
  String get errorAddingEmployee;

  /// Error updating employee information
  ///
  /// In vi, this message translates to:
  /// **'Lỗi thay đổi thông tin nhân viên'**
  String get errorUpdatingEmployee;

  /// Error deleting employee
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi xóa nhân viên'**
  String get errorDeletingEmployee;

  /// Confirm delete employee
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xóa nhân viên này?'**
  String get confirmDeleteEmployee;

  /// Select image
  ///
  /// In vi, this message translates to:
  /// **'Chọn hình ảnh'**
  String get selectImage;

  /// Error message when cannot select image
  ///
  /// In vi, this message translates to:
  /// **'Không thể chọn hình ảnh. Vui lòng kiểm tra quyền truy cập thư viện ảnh và thử lại.'**
  String get cannotSelectImage;

  /// Category name
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục'**
  String get categoryName;

  /// Add category
  ///
  /// In vi, this message translates to:
  /// **'Thêm danh mục'**
  String get addCategory;

  /// Edit category
  ///
  /// In vi, this message translates to:
  /// **'Sửa danh mục'**
  String get editCategory;

  /// Delete category
  ///
  /// In vi, this message translates to:
  /// **'Xóa danh mục'**
  String get deleteCategory;

  /// Category added successfully
  ///
  /// In vi, this message translates to:
  /// **'Danh mục đã được thêm thành công'**
  String get categoryAddedSuccessfully;

  /// Category updated successfully
  ///
  /// In vi, this message translates to:
  /// **'Danh mục đã được cập nhật thành công'**
  String get categoryUpdatedSuccessfully;

  /// Category deleted successfully
  ///
  /// In vi, this message translates to:
  /// **'Xóa danh mục thành công'**
  String get categoryDeletedSuccessfully;

  /// Error adding category
  ///
  /// In vi, this message translates to:
  /// **'Lỗi thêm danh mục'**
  String get errorAddingCategory;

  /// Error updating category information
  ///
  /// In vi, this message translates to:
  /// **'Lỗi thay đổi thông tin danh mục'**
  String get errorUpdatingCategory;

  /// Error deleting category
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi xóa danh mục'**
  String get errorDeletingCategory;

  /// Confirm delete category
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xóa danh mục này?'**
  String get confirmDeleteCategory;

  /// Service name
  ///
  /// In vi, this message translates to:
  /// **'Tên dịch vụ'**
  String get serviceName;

  /// Service price
  ///
  /// In vi, this message translates to:
  /// **'Giá dịch vụ'**
  String get servicePrice;

  /// Service duration
  ///
  /// In vi, this message translates to:
  /// **'Thời gian thực hiện'**
  String get serviceDuration;

  /// Add service
  ///
  /// In vi, this message translates to:
  /// **'Thêm dịch vụ'**
  String get addService;

  /// Edit service
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa dịch vụ'**
  String get editService;

  /// Delete service
  ///
  /// In vi, this message translates to:
  /// **'Xóa dịch vụ'**
  String get deleteService;

  /// Service added successfully
  ///
  /// In vi, this message translates to:
  /// **'Thêm dịch vụ thành công'**
  String get serviceAddedSuccessfully;

  /// Service information updated successfully
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi thông tin dịch vụ thành công'**
  String get serviceUpdatedSuccessfully;

  /// Service deleted successfully
  ///
  /// In vi, this message translates to:
  /// **'Xóa dịch vụ thành công'**
  String get serviceDeletedSuccessfully;

  /// Error adding service
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi thêm dịch vụ'**
  String get errorAddingService;

  /// Error updating service information
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi thay đổi thông tin dịch vụ'**
  String get errorUpdatingService;

  /// Error deleting service
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi xóa dịch vụ'**
  String get errorDeletingService;

  /// Confirm delete service
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xóa dịch vụ này?'**
  String get confirmDeleteService;

  /// Order
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng'**
  String get order;

  /// Orders
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng'**
  String get orders;

  /// Update order screen title
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật đơn hàng'**
  String get updateOrder;

  /// Order created successfully
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo đơn thành công!'**
  String get orderCreatedSuccessfully;

  /// Order updated successfully
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật đơn thành công!'**
  String get orderUpdatedSuccessfully;

  /// Order deleted successfully
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đã được xóa thành công'**
  String get orderDeletedSuccessfully;

  /// Error creating order
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tạo đơn: {error}'**
  String errorCreatingOrder(String error);

  /// Error updating order
  ///
  /// In vi, this message translates to:
  /// **'Lỗi cập nhật đơn: {error}'**
  String errorUpdatingOrder(String error);

  /// Error deleting order
  ///
  /// In vi, this message translates to:
  /// **'Lỗi xóa đơn hàng'**
  String get errorDeletingOrder;

  /// Confirm delete order
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xóa đơn hàng này?'**
  String get confirmDeleteOrder;

  /// Select services
  ///
  /// In vi, this message translates to:
  /// **'Chọn dịch vụ'**
  String get selectServices;

  /// Select employees
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhân viên'**
  String get selectEmployees;

  /// Selected services
  ///
  /// In vi, this message translates to:
  /// **'dịch vụ đã chọn'**
  String get selectedServices;

  /// Selected employees
  ///
  /// In vi, this message translates to:
  /// **'nhân viên đã chọn'**
  String get selectedEmployees;

  /// Please select at least one service
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn ít nhất một dịch vụ'**
  String get pleaseSelectAtLeastOneService;

  /// Please select at least one employee
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn ít nhất một nhân viên'**
  String get pleaseSelectAtLeastOneEmployee;

  /// Can only update order today
  ///
  /// In vi, this message translates to:
  /// **'Chỉ có thể cập nhật đơn hàng trong ngày hôm nay'**
  String get canOnlyUpdateOrderToday;

  /// Customer information section title
  ///
  /// In vi, this message translates to:
  /// **'Thông tin khách hàng'**
  String get customerInformation;

  /// Employee information section title
  ///
  /// In vi, this message translates to:
  /// **'Thông tin nhân viên'**
  String get employeeInformation;

  /// Service categories section title
  ///
  /// In vi, this message translates to:
  /// **'Danh mục dịch vụ'**
  String get serviceCategories;

  /// Performing employee section title
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên thực hiện'**
  String get performingEmployee;

  /// Logged in employee label
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên đăng nhập'**
  String get loggedInEmployee;

  /// Found customer
  ///
  /// In vi, this message translates to:
  /// **'Đã tìm thấy khách hàng'**
  String get foundCustomer;

  /// Customer not found message
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy khách hàng với số điện thoại này. Vui lòng nhập tên để tạo mới.'**
  String get customerNotFound;

  /// Found employee
  ///
  /// In vi, this message translates to:
  /// **'Đã tìm thấy nhân viên'**
  String get foundEmployee;

  /// Employee not found message
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy nhân viên với số điện thoại này. Vui lòng nhập tên để tạo mới.'**
  String get employeeNotFound;

  /// Error loading categories
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải danh mục: {error}'**
  String errorLoadingCategories(String error);

  /// Error loading services
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải dịch vụ: {error}'**
  String errorLoadingServices(String error);

  /// Error loading employees
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải danh sách nhân viên: {error}'**
  String errorLoadingEmployees(String error);

  /// Error searching customer
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tìm kiếm khách hàng: {error}'**
  String errorSearchingCustomer(String error);

  /// Error searching employee
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tìm kiếm nhân viên: {error}'**
  String errorSearchingEmployee(String error);

  /// Invalid service data error
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu dịch vụ không hợp lệ'**
  String get invalidServiceData;

  /// Bill
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn'**
  String get bill;

  /// Bill number
  ///
  /// In vi, this message translates to:
  /// **'Số hóa đơn'**
  String get billNumber;

  /// Bill date
  ///
  /// In vi, this message translates to:
  /// **'Ngày hóa đơn'**
  String get billDate;

  /// Bill total
  ///
  /// In vi, this message translates to:
  /// **'Tổng hóa đơn'**
  String get billTotal;

  /// Bill status
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái hóa đơn'**
  String get billStatus;

  /// Paid status
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get paid;

  /// Unpaid status
  ///
  /// In vi, this message translates to:
  /// **'Chưa thanh toán'**
  String get unpaid;

  /// Pending
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get pending;

  /// Completed
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get completed;

  /// Cancelled
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get cancelled;

  /// Report
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get report;

  /// Daily report
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo ngày'**
  String get dailyReport;

  /// Weekly report
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo tuần'**
  String get weeklyReport;

  /// Monthly report
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo tháng'**
  String get monthlyReport;

  /// Yearly report
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo năm'**
  String get yearlyReport;

  /// Total revenue
  ///
  /// In vi, this message translates to:
  /// **'Tổng doanh thu'**
  String get totalRevenue;

  /// Total orders
  ///
  /// In vi, this message translates to:
  /// **'Tổng đơn hàng'**
  String get totalOrders;

  /// Total customers
  ///
  /// In vi, this message translates to:
  /// **'Tổng khách hàng'**
  String get totalCustomers;

  /// Average order value
  ///
  /// In vi, this message translates to:
  /// **'Giá trị đơn hàng trung bình'**
  String get averageOrderValue;

  /// Salon name
  ///
  /// In vi, this message translates to:
  /// **'Tên salon'**
  String get salonName;

  /// Salon address
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ salon'**
  String get salonAddress;

  /// Salon phone
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại salon'**
  String get salonPhone;

  /// Salon email
  ///
  /// In vi, this message translates to:
  /// **'Email salon'**
  String get salonEmail;

  /// Salon description
  ///
  /// In vi, this message translates to:
  /// **'Mô tả salon'**
  String get salonDescription;

  /// Salon hours
  ///
  /// In vi, this message translates to:
  /// **'Giờ hoạt động'**
  String get salonHours;

  /// Update salon info
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin salon'**
  String get updateSalonInfo;

  /// Salon info updated successfully
  ///
  /// In vi, this message translates to:
  /// **'Thông tin salon đã được cập nhật thành công'**
  String get salonInfoUpdatedSuccessfully;

  /// Error updating salon info
  ///
  /// In vi, this message translates to:
  /// **'Lỗi cập nhật thông tin salon'**
  String get errorUpdatingSalonInfo;

  /// Notifications
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifications;

  /// No notifications
  ///
  /// In vi, this message translates to:
  /// **'Không có thông báo'**
  String get noNotifications;

  /// Mark as read
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã đọc'**
  String get markAsRead;

  /// Mark all as read
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu tất cả đã đọc'**
  String get markAllAsRead;

  /// Clear all
  ///
  /// In vi, this message translates to:
  /// **'Xóa tất cả'**
  String get clearAll;

  /// Minutes
  ///
  /// In vi, this message translates to:
  /// **'phút'**
  String get minutes;

  /// Hours
  ///
  /// In vi, this message translates to:
  /// **'giờ'**
  String get hours;

  /// Days
  ///
  /// In vi, this message translates to:
  /// **'ngày'**
  String get days;

  /// Weeks
  ///
  /// In vi, this message translates to:
  /// **'tuần'**
  String get weeks;

  /// Months
  ///
  /// In vi, this message translates to:
  /// **'tháng'**
  String get months;

  /// Years
  ///
  /// In vi, this message translates to:
  /// **'năm'**
  String get years;

  /// Ago
  ///
  /// In vi, this message translates to:
  /// **'trước'**
  String get ago;

  /// Now
  ///
  /// In vi, this message translates to:
  /// **'bây giờ'**
  String get now;

  /// Today preset button
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get today;

  /// Yesterday preset button
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get yesterday;

  /// Tomorrow
  ///
  /// In vi, this message translates to:
  /// **'ngày mai'**
  String get tomorrow;

  /// Clear filter button text
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc'**
  String get clearFilter;

  /// Apply
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get apply;

  /// Choose action for this item
  ///
  /// In vi, this message translates to:
  /// **'Chọn hành động cho {item} này'**
  String chooseAction(String item);

  /// Try again
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get tryAgain;

  /// No items found
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy {item}'**
  String noItemsFound(String item);

  /// Delete all notifications
  ///
  /// In vi, this message translates to:
  /// **'Xóa tất cả thông báo'**
  String get deleteAllNotifications;

  /// Confirm delete all notifications
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xóa tất cả thông báo?'**
  String get confirmDeleteAllNotifications;

  /// Select QR Code button text
  ///
  /// In vi, this message translates to:
  /// **'Chọn QR Code'**
  String get selectQRCode;

  /// Change logo
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi logo'**
  String get changeLogo;

  /// All employees
  ///
  /// In vi, this message translates to:
  /// **'Tất cả nhân viên'**
  String get allEmployees;

  /// All statuses
  ///
  /// In vi, this message translates to:
  /// **'Tất cả trạng thái'**
  String get allStatuses;

  /// Error loading data
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải dữ liệu: {error}'**
  String errorLoadingData(String error);

  /// Add image
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get addImage;

  /// Category filter
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get categoryFilter;

  /// Select categories to filter services
  ///
  /// In vi, this message translates to:
  /// **'Chọn danh mục và sắp xếp'**
  String get selectCategoriesToFilter;

  /// Number of categories selected
  ///
  /// In vi, this message translates to:
  /// **'{count} danh mục đã chọn'**
  String categoriesSelected(int count);

  /// Selected categories
  ///
  /// In vi, this message translates to:
  /// **'Danh mục đã chọn'**
  String get selectedCategories;

  /// Remove all
  ///
  /// In vi, this message translates to:
  /// **'Xóa tất cả'**
  String get removeAll;

  /// All categories
  ///
  /// In vi, this message translates to:
  /// **'Tất cả danh mục ({count})'**
  String allCategories(int count);

  /// Create new service
  ///
  /// In vi, this message translates to:
  /// **'Tạo dịch vụ mới'**
  String get createNewService;

  /// Please enter service name
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên dịch vụ'**
  String get pleaseEnterServiceName;

  /// Please enter price
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập giá'**
  String get pleaseEnterPrice;

  /// Please enter valid price
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập giá hợp lệ'**
  String get pleaseEnterValidPrice;

  /// Error uploading image to server
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi upload ảnh lên server'**
  String get errorUploadingImage;

  /// Update service information
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin dịch vụ'**
  String get updateServiceInfo;

  /// Category name is required
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục không được để trống'**
  String get categoryNameRequired;

  /// Employee phone number already exists
  ///
  /// In vi, this message translates to:
  /// **'SĐT của nhân viên đã được tạo'**
  String get employeePhoneExists;

  /// Customer phone number already exists
  ///
  /// In vi, this message translates to:
  /// **'SĐT của khách hàng đã được tạo'**
  String get customerPhoneExists;

  /// Error uploading logo to server
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi upload logo lên server'**
  String get errorUploadingLogo;

  /// Error uploading QR code to server
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi upload QR code lên server'**
  String get errorUploadingQRCode;

  /// Salon information saved successfully
  ///
  /// In vi, this message translates to:
  /// **'Lưu thông tin salon thành công!'**
  String get salonInfoSavedSuccessfully;

  /// Full name
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get fullName;

  /// Database username
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập Database'**
  String get databaseUsername;

  /// Database password field label
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu Database'**
  String get databasePassword;

  /// Vietnamese Dong currency
  ///
  /// In vi, this message translates to:
  /// **'VNĐ'**
  String get vnd;

  /// Hours ago
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ trước'**
  String hoursAgo(int hours);

  /// Minutes ago
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút trước'**
  String minutesAgo(int minutes);

  /// Just now
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong'**
  String get justNow;

  /// Enter new customer information
  ///
  /// In vi, this message translates to:
  /// **'Nhập thông tin khách hàng mới'**
  String get enterNewCustomerInfo;

  /// Update customer information
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin khách hàng'**
  String get updateCustomerInfo;

  /// Phone label
  ///
  /// In vi, this message translates to:
  /// **'SĐT: {phone}'**
  String phoneLabel(String phone);

  /// Customer
  ///
  /// In vi, this message translates to:
  /// **'khách hàng'**
  String get customer;

  /// Customers title
  ///
  /// In vi, this message translates to:
  /// **'Khách hàng'**
  String get customersTitle;

  /// Manage customer information
  ///
  /// In vi, this message translates to:
  /// **'Quản lý thông tin khách hàng'**
  String get manageCustomerInfo;

  /// Search customers
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm khách hàng...'**
  String get searchCustomers;

  /// Error loading customer list
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải danh sách khách hàng'**
  String get errorLoadingCustomerList;

  /// Cannot load customer list
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách khách hàng'**
  String get cannotLoadCustomerList;

  /// Please check network connection or try again
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra kết nối mạng hoặc thử lại'**
  String get checkNetworkOrTryAgain;

  /// Enter new employee information
  ///
  /// In vi, this message translates to:
  /// **'Nhập thông tin nhân viên mới'**
  String get enterNewEmployeeInfo;

  /// Please enter full name
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ và tên'**
  String get pleaseEnterFullName;

  /// Phone number validation message
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số điện thoại'**
  String get pleaseEnterPhoneNumber;

  /// Error uploading image to server
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi upload ảnh lên server: {error}'**
  String errorUploadingImageToServer(String error);

  /// Update employee information
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin nhân viên'**
  String get updateEmployeeInfo;

  /// New password optional
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới (để trống nếu không đổi)'**
  String get newPasswordOptional;

  /// Employee information updated successfully
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi thông tin nhân viên thành công'**
  String get employeeInfoUpdatedSuccessfully;

  /// Manage salon employees
  ///
  /// In vi, this message translates to:
  /// **'Quản lý nhân viên salon'**
  String get manageSalonEmployees;

  /// Search employees
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm nhân viên...'**
  String get searchEmployees;

  /// Error loading employee list
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải danh sách nhân viên'**
  String get errorLoadingEmployeeList;

  /// Cannot load employee list
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách nhân viên'**
  String get cannotLoadEmployeeList;

  /// Update category information
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin danh mục'**
  String get updateCategoryInfo;

  /// Category information updated successfully
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi thông tin danh mục thành công'**
  String get categoryInfoUpdatedSuccessfully;

  /// Category
  ///
  /// In vi, this message translates to:
  /// **'danh mục'**
  String get category;

  /// Categories title
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get categoriesTitle;

  /// Categories list description
  ///
  /// In vi, this message translates to:
  /// **'Danh sách danh mục dịch vụ'**
  String get categoriesListDescription;

  /// Search categories
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm danh mục...'**
  String get searchCategories;

  /// Error loading categories list
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải danh sách danh mục'**
  String get errorLoadingCategoriesList;

  /// Cannot load categories list
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách danh mục'**
  String get cannotLoadCategoriesList;

  /// Please check network connection or try again
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra kết nối mạng hoặc thử lại'**
  String get checkNetworkOrTryAgainCategories;

  /// Services title
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ'**
  String get servicesTitle;

  /// Services subtitle
  ///
  /// In vi, this message translates to:
  /// **'Quản lý dịch vụ theo danh mục'**
  String get servicesSubtitle;

  /// Search services placeholder
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm dịch vụ...'**
  String get searchServices;

  /// Showing all services message
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị tất cả {total} dịch vụ'**
  String showingAllServices(int total);

  /// Found services with category and search filter
  ///
  /// In vi, this message translates to:
  /// **'Tìm thấy {shown}/{total} dịch vụ (lọc theo danh mục và tìm kiếm)'**
  String foundServicesWithCategoryAndSearch(int shown, int total);

  /// Found services with category filter
  ///
  /// In vi, this message translates to:
  /// **'Tìm thấy {shown}/{total} dịch vụ (lọc theo {count} danh mục)'**
  String foundServicesWithCategory(int shown, int total, int count);

  /// Found services with search filter
  ///
  /// In vi, this message translates to:
  /// **'Tìm thấy {shown}/{total} dịch vụ (tìm kiếm: \"{search}\")'**
  String foundServicesWithSearch(int shown, int total, String search);

  /// Clear filters button
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc'**
  String get clearFilters;

  /// Error loading services list
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải danh sách dịch vụ'**
  String get errorLoadingServicesList;

  /// Cannot load services list
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách dịch vụ'**
  String get cannotLoadServicesList;

  /// Please check network connection or try again
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra kết nối mạng hoặc thử lại'**
  String get checkNetworkOrTryAgainServices;

  /// Service
  ///
  /// In vi, this message translates to:
  /// **'dịch vụ'**
  String get service;

  /// Customer found message
  ///
  /// In vi, this message translates to:
  /// **'Đã tìm thấy khách hàng: {name}'**
  String customerFound(String name);

  /// Employee found message
  ///
  /// In vi, this message translates to:
  /// **'Đã tìm thấy nhân viên: {name}'**
  String employeeFound(String name);

  /// Title for creating new order
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn mới'**
  String get createNewOrder;

  /// Number of services selected
  ///
  /// In vi, this message translates to:
  /// **'{count} dịch vụ đã chọn'**
  String servicesSelected(int count);

  /// Customer name validation message
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên khách hàng'**
  String get pleaseEnterCustomerName;

  /// Select employee dropdown label
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhân viên'**
  String get selectEmployee;

  /// Number of employees selected
  ///
  /// In vi, this message translates to:
  /// **'{count} nhân viên đã chọn'**
  String employeesSelected(int count);

  /// Select category dropdown label
  ///
  /// In vi, this message translates to:
  /// **'Chọn danh mục'**
  String get selectCategory;

  /// Select service dropdown label
  ///
  /// In vi, this message translates to:
  /// **'Chọn dịch vụ'**
  String get selectService;

  /// Number of services selected
  ///
  /// In vi, this message translates to:
  /// **'{count} dịch vụ đã chọn'**
  String servicesSelectedCount(int count);

  /// Discount section title
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá'**
  String get discount;

  /// Discount validation message
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá phải từ 0-100%'**
  String get discountMustBe0To100;

  /// Discount amount display
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá: {amount} VNĐ'**
  String discountAmount(String amount);

  /// Tip section title
  ///
  /// In vi, this message translates to:
  /// **'Tiền bo'**
  String get tip;

  /// Tip validation message
  ///
  /// In vi, this message translates to:
  /// **'Tiền bo phải lớn hơn 0'**
  String get tipMustBeGreaterThan0;

  /// Tip amount display
  ///
  /// In vi, this message translates to:
  /// **'Tip: {amount} VNĐ'**
  String tipAmount(String amount);

  /// Tax section title
  ///
  /// In vi, this message translates to:
  /// **'Thuế'**
  String get tax;

  /// Validation message for tax percentage
  ///
  /// In vi, this message translates to:
  /// **'Thuế phải từ 0-100%'**
  String get taxMustBe0To100;

  /// Tax amount display
  ///
  /// In vi, this message translates to:
  /// **'Thuế: {amount} VNĐ'**
  String taxAmount(String amount);

  /// Tax label
  ///
  /// In vi, this message translates to:
  /// **'Thuế'**
  String get taxLabel;

  /// Positive tax amount display
  ///
  /// In vi, this message translates to:
  /// **'+{amount} VNĐ'**
  String taxAmountPositive(String amount);

  /// Subtotal label
  ///
  /// In vi, this message translates to:
  /// **'Thành tiền'**
  String get subtotal;

  /// Subtotal amount display
  ///
  /// In vi, this message translates to:
  /// **'{amount} VNĐ'**
  String subtotalAmount(String amount);

  /// Discount percentage display
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá ({percentage}%)'**
  String discountPercentage(String percentage);

  /// Negative discount amount display
  ///
  /// In vi, this message translates to:
  /// **'-{amount} VNĐ'**
  String discountAmountNegative(String amount);

  /// Tip label
  ///
  /// In vi, this message translates to:
  /// **'Tiền bo'**
  String get tipLabel;

  /// Positive tip amount display
  ///
  /// In vi, this message translates to:
  /// **'+{amount} VNĐ'**
  String tipAmountPositive(String amount);

  /// Total payment label
  ///
  /// In vi, this message translates to:
  /// **'Tổng thanh toán'**
  String get totalPayment;

  /// Total payment amount display
  ///
  /// In vi, this message translates to:
  /// **'{amount} VNĐ'**
  String totalPaymentAmount(String amount);

  /// Refresh button label
  ///
  /// In vi, this message translates to:
  /// **'Làm mới'**
  String get refresh;

  /// Select text for dropdowns
  ///
  /// In vi, this message translates to:
  /// **'Chọn'**
  String get select;

  /// Error message when cannot load salon information
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin salon. Vui lòng kiểm tra kết nối mạng và thử lại.'**
  String get cannotLoadSalonInfo;

  /// Error message when cannot save salon information
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu thông tin salon. Vui lòng kiểm tra kết nối mạng và thử lại.'**
  String get cannotSaveSalonInfo;

  /// Basic information section title
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cơ bản'**
  String get basicInformation;

  /// Social media section title
  ///
  /// In vi, this message translates to:
  /// **'Mạng xã hội'**
  String get socialMedia;

  /// Salon information title
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get salonInformation;

  /// Description for salon information management
  ///
  /// In vi, this message translates to:
  /// **'Quản lý thông tin và liên hệ'**
  String get manageSalonInfoAndContact;

  /// QR Code section title
  ///
  /// In vi, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// Logo section title
  ///
  /// In vi, this message translates to:
  /// **'Logo'**
  String get salonLogo;

  /// Select Logo button text
  ///
  /// In vi, this message translates to:
  /// **'Chọn Logo'**
  String get selectLogo;

  /// Salon name field label
  ///
  /// In vi, this message translates to:
  /// **'Tên Salon'**
  String get salonNameLabel;

  /// Address field label
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ'**
  String get addressLabel;

  /// Phone number field label
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get phoneNumberLabel;

  /// Email field label
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Website field label
  ///
  /// In vi, this message translates to:
  /// **'Website'**
  String get websiteLabel;

  /// Facebook field label
  ///
  /// In vi, this message translates to:
  /// **'Facebook'**
  String get facebookLabel;

  /// Instagram field label
  ///
  /// In vi, this message translates to:
  /// **'Instagram'**
  String get instagramLabel;

  /// Zalo field label
  ///
  /// In vi, this message translates to:
  /// **'Zalo'**
  String get zaloLabel;

  /// Saving status text
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get saving;

  /// Save information button text
  ///
  /// In vi, this message translates to:
  /// **'Lưu thông tin'**
  String get saveInformation;

  /// Menu screen title
  ///
  /// In vi, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// Menu screen subtitle
  ///
  /// In vi, this message translates to:
  /// **'Menu danh mục và dịch vụ'**
  String get menuSubtitle;

  /// Search services placeholder
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm dịch vụ...'**
  String get searchServicesPlaceholder;

  /// No categories available message
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh mục nào'**
  String get noCategoriesYet;

  /// Categories section title
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get categoriesSection;

  /// Services count display
  ///
  /// In vi, this message translates to:
  /// **'{count} dịch vụ'**
  String servicesCount(int count);

  /// Categories count display
  ///
  /// In vi, this message translates to:
  /// **'{count} danh mục'**
  String categoriesCount(int count);

  /// Services section title
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ'**
  String get servicesSection;

  /// View all services button text
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả dịch vụ'**
  String get viewAllServices;

  /// No services found with search and category filter
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy dịch vụ \"{search}\" trong {category}'**
  String noServicesFoundWithSearchAndCategory(String search, String category);

  /// No services found with search filter
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy dịch vụ \"{search}\"'**
  String noServicesFoundWithSearch(String search);

  /// No services in category message
  ///
  /// In vi, this message translates to:
  /// **'Danh mục \"{category}\" chưa có dịch vụ nào'**
  String noServicesInCategory(String category);

  /// No services available message
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dịch vụ nào'**
  String get noServicesYet;

  /// Unknown category name
  ///
  /// In vi, this message translates to:
  /// **'Không xác định'**
  String get unknownCategory;

  /// Bills management subtitle
  ///
  /// In vi, this message translates to:
  /// **'Quản lý hóa đơn'**
  String get billsManagement;

  /// Search bills placeholder text
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm hóa đơn...'**
  String get searchBills;

  /// Filter by time dialog title
  ///
  /// In vi, this message translates to:
  /// **'Lọc theo thời gian'**
  String get filterByTime;

  /// Select time range to view bills description
  ///
  /// In vi, this message translates to:
  /// **'Chọn khoảng thời gian để xem hóa đơn'**
  String get selectTimeRangeToViewBills;

  /// Custom time range button text
  ///
  /// In vi, this message translates to:
  /// **'Chọn khoảng thời gian tùy chỉnh'**
  String get selectCustomTimeRange;

  /// Custom time range button subtitle
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày bắt đầu và kết thúc'**
  String get selectStartAndEndDate;

  /// Quick select section title
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhanh'**
  String get quickSelect;

  /// Close button text
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// This week preset button
  ///
  /// In vi, this message translates to:
  /// **'Tuần này'**
  String get thisWeek;

  /// This month preset button
  ///
  /// In vi, this message translates to:
  /// **'Tháng này'**
  String get thisMonth;

  /// Last 30 days preset button
  ///
  /// In vi, this message translates to:
  /// **'30 ngày qua'**
  String get last30Days;

  /// No bills in time range message
  ///
  /// In vi, this message translates to:
  /// **'Không có hóa đơn trong khoảng thời gian này'**
  String get noBillsInTimeRange;

  /// No bills found message
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy hóa đơn'**
  String get noBillsFound;

  /// No bills yet message
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hóa đơn nào'**
  String get noBillsYet;

  /// No your bills in time range message
  ///
  /// In vi, this message translates to:
  /// **'Không có hóa đơn của bạn trong khoảng thời gian này'**
  String get noYourBillsInTimeRange;

  /// No your bills found message
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy hóa đơn của bạn'**
  String get noYourBillsFound;

  /// No your bills yet message
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có hóa đơn nào'**
  String get noYourBillsYet;

  /// Empty state message for time range filter
  ///
  /// In vi, this message translates to:
  /// **'Thử chọn khoảng thời gian khác hoặc xóa bộ lọc thời gian'**
  String get tryDifferentTimeRange;

  /// Empty state message for search
  ///
  /// In vi, this message translates to:
  /// **'Thử tìm kiếm với từ khóa khác'**
  String get tryDifferentSearch;

  /// Create first order to view bills message
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn hàng đầu tiên để xem hóa đơn ở đây'**
  String get createFirstOrderToViewBills;

  /// Create first order to view your bills message
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn hàng đầu tiên để xem hóa đơn của bạn ở đây'**
  String get createFirstOrderToViewYourBills;

  /// Filtered suffix
  ///
  /// In vi, this message translates to:
  /// **'đã lọc'**
  String get filtered;

  /// Total amount label
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền'**
  String get totalAmount;

  /// No services available message
  ///
  /// In vi, this message translates to:
  /// **'Không có dịch vụ'**
  String get noServices;

  /// Temporary placeholder text
  ///
  /// In vi, this message translates to:
  /// **'TẠM THỜI'**
  String get temporary;

  /// Cannot update order today only message
  ///
  /// In vi, this message translates to:
  /// **'Chỉ có thể cập nhật đơn hàng trong ngày hôm nay'**
  String get cannotUpdateOrderTodayOnly;

  /// Service info not found message
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thông tin dịch vụ cho đơn hàng này'**
  String get serviceInfoNotFound;

  /// Filter by time dialog subtitle
  ///
  /// In vi, this message translates to:
  /// **'Chọn khoảng thời gian để xem báo cáo'**
  String get selectTimeRangeToViewReports;

  /// Revenue reports screen title
  ///
  /// In vi, this message translates to:
  /// **'Báo Cáo Doanh Thu'**
  String get revenueReports;

  /// Revenue reports screen subtitle
  ///
  /// In vi, this message translates to:
  /// **'Thống kê và báo cáo doanh thu'**
  String get statisticsAndRevenueReports;

  /// Search field hint text
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm...'**
  String get searchHint;

  /// Payment status section title
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái thanh toán'**
  String get paymentStatus;

  /// Discount percentage display
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá ({percent}%)'**
  String discountPercent(String percent);

  /// Empty state when no orders in selected time range
  ///
  /// In vi, this message translates to:
  /// **'Không có hóa đơn trong khoảng thời gian này'**
  String get noOrdersInTimeRange;

  /// Empty state when search returns no results
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy hóa đơn'**
  String get noOrdersFound;

  /// Empty state when no orders exist
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hóa đơn nào'**
  String get noOrdersYet;

  /// Empty state message for no orders
  ///
  /// In vi, this message translates to:
  /// **'Tạo hóa đơn đầu tiên để xem báo cáo ở đây'**
  String get createFirstOrderToViewReports;

  /// Bill payment receipt title
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn thanh toán'**
  String get billPaymentReceipt;

  /// Print button label
  ///
  /// In vi, this message translates to:
  /// **'In'**
  String get print;

  /// Bill code label
  ///
  /// In vi, this message translates to:
  /// **'Mã hóa đơn'**
  String get billCode;

  /// Created date label
  ///
  /// In vi, this message translates to:
  /// **'Ngày tạo'**
  String get createdDate;

  /// Serving staff label
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên phục vụ'**
  String get servingStaff;

  /// Service details section title
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết dịch vụ'**
  String get serviceDetails;

  /// QR Code payment section title
  ///
  /// In vi, this message translates to:
  /// **'QR Code thanh toán'**
  String get qrCodePayment;

  /// No QR code message
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mã QR Code'**
  String get noQrCode;

  /// QR Code display error message
  ///
  /// In vi, this message translates to:
  /// **'Lỗi hiển thị QR Code'**
  String get qrCodeDisplayError;

  /// Scan QR code to pay instruction
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR để thanh toán'**
  String get scanQrToPay;

  /// Service not found error message
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thông tin dịch vụ cho đơn hàng này'**
  String get serviceNotFoundError;

  /// Bill footer message
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn quý khách đã sử dụng dịch vụ!'**
  String get billFooter;

  /// Bill footer second message
  ///
  /// In vi, this message translates to:
  /// **'Hẹn gặp lại quý khách!'**
  String get billFooter2;

  /// Warning message for updating orders
  ///
  /// In vi, this message translates to:
  /// **'Chỉ có thể cập nhật đơn hàng trong ngày hôm nay'**
  String get canOnlyUpdateTodayOrders;

  /// Customer paid fully message
  ///
  /// In vi, this message translates to:
  /// **'Khách hàng đã thanh toán đầy đủ'**
  String get customerPaidFully;

  /// Customer not paid message
  ///
  /// In vi, this message translates to:
  /// **'Khách hàng chưa thanh toán'**
  String get customerNotPaid;

  /// Total payment label
  ///
  /// In vi, this message translates to:
  /// **'Tổng thanh toán'**
  String get totalPaymentLabel;

  /// Error message when order is not found
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thông tin đơn hàng'**
  String get orderNotFound;

  /// Error message when loading order fails
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi tải thông tin đơn hàng: {error}'**
  String errorLoadingOrder(String error);

  /// Cannot connect to server error message
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.'**
  String get cannotConnectToServer;

  /// Warning message when notification lacks order data
  ///
  /// In vi, this message translates to:
  /// **'Thông báo không chứa thông tin đơn hàng'**
  String get notificationNoOrderInfo;

  /// Success message when marking all notifications as read
  ///
  /// In vi, this message translates to:
  /// **'Đã đánh dấu tất cả thông báo là đã đọc'**
  String get allNotificationsMarkedAsRead;

  /// Success message when notification is deleted
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa thông báo'**
  String get notificationDeleted;

  /// Error message when deleting notification fails
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi xóa thông báo: {error}'**
  String errorDeletingNotification(String error);

  /// Success message when all notifications are deleted
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa tất cả thông báo'**
  String get allNotificationsDeleted;

  /// Error message when deleting all notifications fails
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi xóa tất cả thông báo: {error}'**
  String errorDeletingAllNotifications(String error);

  /// Tooltip for mark all as read button
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu tất cả đã đọc'**
  String get markAllAsReadTooltip;

  /// Tooltip for clear all button
  ///
  /// In vi, this message translates to:
  /// **'Xóa tất cả'**
  String get clearAllTooltip;

  /// Empty state message when no notifications exist
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo nào'**
  String get noNotificationsYet;

  /// Empty state description for notifications
  ///
  /// In vi, this message translates to:
  /// **'Các thông báo mới sẽ xuất hiện ở đây'**
  String get newNotificationsWillAppearHere;

  /// Delete action in popup menu
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get deleteAction;

  /// Error message when creating PDF fails
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tạo PDF: {error}'**
  String pdfErrorCreating(String error);

  /// Error message when plugin is not supported on platform
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: Plugin không được hỗ trợ trên platform này. Vui lòng chạy trên Android/iOS hoặc cài đặt CocoaPods cho macOS.'**
  String get pdfErrorPluginNotSupported;

  /// Error message when sharing to Zalo fails
  ///
  /// In vi, this message translates to:
  /// **'Lỗi chia sẻ Zalo: {error}'**
  String pdfErrorSharingZalo(String error);

  /// Error message when sharing file fails
  ///
  /// In vi, this message translates to:
  /// **'Lỗi chia sẻ file: {error}'**
  String pdfErrorSharingFile(String error);

  /// Error message when file cannot be shared
  ///
  /// In vi, this message translates to:
  /// **'Không thể chia sẻ file: {error}'**
  String pdfErrorCannotShare(String error);

  /// Error message when no PDF file or data available for sharing
  ///
  /// In vi, this message translates to:
  /// **'Không có file PDF hoặc dữ liệu để chia sẻ'**
  String get pdfErrorNoFileData;

  /// Error message when no PDF file available for sharing
  ///
  /// In vi, this message translates to:
  /// **'Không có file PDF để chia sẻ'**
  String get pdfErrorNoFileToShare;

  /// Message when Zalo is opened for sharing
  ///
  /// In vi, this message translates to:
  /// **'Zalo đã mở! Vui lòng chọn Zalo trong menu chia sẻ để gửi hóa đơn.'**
  String get pdfZaloOpened;

  /// Bill sharing text with salon name
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn từ {salonName}'**
  String pdfBillFrom(String salonName);

  /// Message when PDF file is created and needs manual sharing
  ///
  /// In vi, this message translates to:
  /// **'File PDF đã được tạo. Vui lòng chia sẻ thủ công.'**
  String get pdfFileCreatedManualShare;

  /// Phone number label in PDF
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại: {phoneNumber}'**
  String pdfPhoneNumber(String phoneNumber);

  /// Bill information section title in PDF
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN HÓA ĐƠN'**
  String get pdfBillInfoTitle;

  /// Bill code label in PDF
  ///
  /// In vi, this message translates to:
  /// **'Mã hóa đơn'**
  String get pdfBillCode;

  /// Created date label in PDF
  ///
  /// In vi, this message translates to:
  /// **'Ngày tạo'**
  String get pdfCreatedDate;

  /// Customer information section title in PDF
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN KHÁCH HÀNG'**
  String get pdfCustomerInfoTitle;

  /// Customer name label in PDF
  ///
  /// In vi, this message translates to:
  /// **'Tên khách hàng'**
  String get pdfCustomerName;

  /// Customer phone label in PDF
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get pdfCustomerPhone;

  /// Employee served label in PDF
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên phục vụ'**
  String get pdfEmployeeServed;

  /// Services detail section title in PDF
  ///
  /// In vi, this message translates to:
  /// **'CHI TIẾT DỊCH VỤ'**
  String get pdfServicesDetailTitle;

  /// Payment information section title in PDF
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN THANH TOÁN'**
  String get pdfPaymentInfoTitle;

  /// Subtotal label in PDF
  ///
  /// In vi, this message translates to:
  /// **'Thành tiền'**
  String get pdfSubtotal;

  /// Discount label in PDF with percentage
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá ({percent}%)'**
  String pdfDiscount(String percent);

  /// Tip label in PDF
  ///
  /// In vi, this message translates to:
  /// **'Tiền bo'**
  String get pdfTip;

  /// Total payment label in PDF
  ///
  /// In vi, this message translates to:
  /// **'TỔNG THANH TOÁN'**
  String get pdfTotalPayment;

  /// Thank you message in PDF footer
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn quý khách đã sử dụng dịch vụ!'**
  String get pdfThankYouMessage;

  /// See you again message in PDF footer
  ///
  /// In vi, this message translates to:
  /// **'Hẹn gặp lại quý khách!'**
  String get pdfSeeYouAgainMessage;

  /// Share bill dialog title
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ hóa đơn'**
  String get pdfShareBillTitle;

  /// Share bill dialog message
  ///
  /// In vi, this message translates to:
  /// **'Chọn cách chia sẻ hóa đơn'**
  String get pdfShareBillMessage;

  /// Zalo sharing option
  ///
  /// In vi, this message translates to:
  /// **'Zalo'**
  String get pdfShareZalo;

  /// Other sharing option
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get pdfShareOther;

  /// Cancel button text
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get pdfCancel;

  /// PDF file created dialog title
  ///
  /// In vi, this message translates to:
  /// **'File PDF đã được tạo'**
  String get pdfFileCreatedTitle;

  /// PDF file created success message
  ///
  /// In vi, this message translates to:
  /// **'File PDF đã được tạo thành công!'**
  String get pdfFileCreatedSuccess;

  /// PDF file path label
  ///
  /// In vi, this message translates to:
  /// **'Đường dẫn: {filePath}'**
  String pdfFilePath(String filePath);

  /// What you can do label
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể'**
  String get pdfYouCanDo;

  /// Open file with PDF app option
  ///
  /// In vi, this message translates to:
  /// **'• Mở file bằng ứng dụng PDF'**
  String get pdfOpenWithApp;

  /// Share file manually option
  ///
  /// In vi, this message translates to:
  /// **'• Chia sẻ file thủ công'**
  String get pdfShareManually;

  /// Send via email option
  ///
  /// In vi, this message translates to:
  /// **'• Gửi qua email'**
  String get pdfSendViaEmail;

  /// Close button text
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get pdfClose;

  /// Open file button text
  ///
  /// In vi, this message translates to:
  /// **'Mở file'**
  String get pdfOpenFile;

  /// File path copied to clipboard message
  ///
  /// In vi, this message translates to:
  /// **'Đã copy đường dẫn file vào clipboard: {filePath}'**
  String pdfPathCopiedToClipboard(String filePath);

  /// Temporary bill ID when order ID is empty
  ///
  /// In vi, this message translates to:
  /// **'TẠM THỜI'**
  String get pdfTemporaryBillId;

  /// Service quantity display format in PDF
  ///
  /// In vi, this message translates to:
  /// **'x{quantity}'**
  String pdfServiceQuantity(Object quantity);

  /// Role selection subtitle
  ///
  /// In vi, this message translates to:
  /// **'Chọn loại tài khoản để tiếp tục'**
  String get selectAccountTypeToContinue;

  /// Connect button text
  ///
  /// In vi, this message translates to:
  /// **'Kết nối'**
  String get connect;

  /// Email check subtitle
  ///
  /// In vi, this message translates to:
  /// **'Nhập email để kiểm tra tài khoản'**
  String get enterEmailToCheckAccount;

  /// Password login subtitle
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu để đăng nhập'**
  String get enterPasswordToLogin;

  /// Create account subtitle
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản mới cho'**
  String get createNewAccountFor;

  /// Create new account text
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản mới'**
  String get createNewAccount;

  /// Employee login subtitle
  ///
  /// In vi, this message translates to:
  /// **'Nhập thông tin đăng nhập nhân viên'**
  String get enterEmployeeLoginInfo;

  /// Continue button text
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get continueText;

  /// Shop owner description
  ///
  /// In vi, this message translates to:
  /// **'Quản lý toàn bộ hệ thống'**
  String get manageEntireSystem;

  /// Employee description
  ///
  /// In vi, this message translates to:
  /// **'Truy cập dịch vụ, tạo đơn và hóa đơn'**
  String get accessServicesCreateOrdersAndBills;

  /// Please enter your email validation message
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email của bạn'**
  String get pleaseEnterYourEmail;

  /// Invalid email example validation message
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ (ví dụ: example@email.com)'**
  String get invalidEmailExample;

  /// Invalid email missing domain validation message
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ (thiếu domain)'**
  String get invalidEmailMissingDomain;

  /// Email exists in system message
  ///
  /// In vi, this message translates to:
  /// **'Email đã tồn tại trong hệ thống'**
  String get emailExistsInSystem;

  /// Email not exists will create new account message
  ///
  /// In vi, this message translates to:
  /// **'Email chưa tồn tại, sẽ tạo tài khoản mới'**
  String get emailNotExistsWillCreateNew;

  /// Please enter password validation message
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get pleaseEnterPasswordValidation;

  /// Password minimum length validation message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 8 ký tự'**
  String get passwordMinLength;

  /// Password must have uppercase validation message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 1 chữ hoa (A-Z)'**
  String get passwordMustHaveUppercase;

  /// Password must have lowercase validation message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 1 chữ thường (a-z)'**
  String get passwordMustHaveLowercase;

  /// Password must have number validation message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 1 số (0-9)'**
  String get passwordMustHaveNumber;

  /// Password must have special character validation message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 1 ký tự đặc biệt'**
  String get passwordMustHaveSpecialChar;

  /// Database label
  ///
  /// In vi, this message translates to:
  /// **'Database'**
  String get database;

  /// Database login username field label
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập Database'**
  String get databaseLoginUsername;

  /// Please enter database username validation message
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên đăng nhập database'**
  String get pleaseEnterDatabaseUsername;

  /// Please enter database password validation message
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu database'**
  String get pleaseEnterDatabasePassword;

  /// Database password minimum length validation message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu database phải có ít nhất 8 ký tự'**
  String get databasePasswordMinLength;

  /// Database password must have uppercase validation message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu database phải có ít nhất 1 chữ hoa (A-Z)'**
  String get databasePasswordMustHaveUppercase;

  /// Database password must have lowercase validation message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu database phải có ít nhất 1 chữ thường (a-z)'**
  String get databasePasswordMustHaveLowercase;

  /// Database password must have number validation message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu database phải có ít nhất 1 số (0-9)'**
  String get databasePasswordMustHaveNumber;

  /// Database password must have special character validation message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu database phải có ít nhất 1 ký tự đặc biệt'**
  String get databasePasswordMustHaveSpecialChar;

  /// Welcome back message
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng quay trở lại'**
  String get welcomeBack;

  /// Password incorrect error message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu không chính xác. Vui lòng kiểm tra lại.'**
  String get passwordIncorrect;

  /// Database login info incorrect error message
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đăng nhập database không chính xác. Vui lòng kiểm tra lại.'**
  String get databaseLoginInfoIncorrect;

  /// Database username incorrect error message
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập database không chính xác.'**
  String get databaseUsernameIncorrect;

  /// Database password incorrect error message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu database không chính xác.'**
  String get databasePasswordIncorrect;

  /// Account created but database error message
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản thành công nhưng không thể tạo database. Vui lòng liên hệ admin.'**
  String get accountCreatedButDatabaseError;

  /// Database password not strong enough error message
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu database không đủ mạnh. Vui lòng kiểm tra yêu cầu bên dưới.'**
  String get databasePasswordNotStrongEnough;

  /// Login info incorrect error message
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đăng nhập không chính xác. Vui lòng kiểm tra lại.'**
  String get loginInfoIncorrect;

  /// System error occurred message
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.'**
  String get systemErrorOccurred;

  /// Connection timeout error message
  ///
  /// In vi, this message translates to:
  /// **'Kết nối bị timeout. Vui lòng thử lại.'**
  String get connectionTimeout;

  /// Network connection error message
  ///
  /// In vi, this message translates to:
  /// **'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.'**
  String get networkConnectionError;

  /// Error occurred please try again message
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi. Vui lòng thử lại sau.'**
  String get errorOccurredPleaseTryAgain;

  /// Customer code field
  ///
  /// In vi, this message translates to:
  /// **'Mã số'**
  String get code;

  /// Trường đơn vị tính
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị'**
  String get unit;

  /// Trường mã dịch vụ
  ///
  /// In vi, this message translates to:
  /// **'Mã dịch vụ'**
  String get serviceCode;

  /// Trường đơn vị tính cho dịch vụ
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị tính'**
  String get unitOfMeasurement;

  /// No description provided for @sortBy.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp theo'**
  String get sortBy;

  /// No description provided for @sortAlphabeticalAZ.
  ///
  /// In vi, this message translates to:
  /// **'A-Z'**
  String get sortAlphabeticalAZ;

  /// No description provided for @sortAlphabeticalZA.
  ///
  /// In vi, this message translates to:
  /// **'Z-A'**
  String get sortAlphabeticalZA;

  /// No description provided for @sortNewestFirst.
  ///
  /// In vi, this message translates to:
  /// **'Mới nhất'**
  String get sortNewestFirst;

  /// No description provided for @sortOldestFirst.
  ///
  /// In vi, this message translates to:
  /// **'Cũ nhất'**
  String get sortOldestFirst;

  /// No description provided for @sortPriceHighToLow.
  ///
  /// In vi, this message translates to:
  /// **'Giá: Cao đến thấp'**
  String get sortPriceHighToLow;

  /// No description provided for @sortPriceLowToHigh.
  ///
  /// In vi, this message translates to:
  /// **'Giá: Thấp đến cao'**
  String get sortPriceLowToHigh;

  /// No description provided for @applySorting.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng sắp xếp'**
  String get applySorting;

  /// No description provided for @clearSorting.
  ///
  /// In vi, this message translates to:
  /// **'Xóa sắp xếp'**
  String get clearSorting;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
