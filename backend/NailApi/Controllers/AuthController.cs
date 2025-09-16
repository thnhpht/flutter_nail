using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using NailApi.Data;
using NailApi.Models;
using NailApi.Services;
using System.Data;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IJwtService _jwtService;
        private readonly IPasswordService _passwordService;

        public AuthController(AppDbContext context, IConfiguration configuration, IJwtService jwtService, IPasswordService passwordService)
        {
            _context = context;
            _configuration = configuration;
            _jwtService = jwtService;
            _passwordService = passwordService;
        }

        [HttpPost("check-email")]
        public async Task<ActionResult<CheckEmailResponse>> CheckEmail([FromBody] CheckEmailRequest request)
        {
            try
            {
                var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);

                if (existingUser != null)
                {
                    return Ok(new CheckEmailResponse
                    {
                        Exists = true,
                        Message = "Email đã tồn tại trong hệ thống! Vui lòng nhập mật khẩu để đăng nhập."
                    });
                }
                else
                {
                    return Ok(new CheckEmailResponse
                    {
                        Exists = false,
                        Message = "Email chưa tồn tại. Vui lòng tạo tài khoản mới!"
                    });
                }
            }
            catch (Exception)
            {
                return StatusCode(500, new CheckEmailResponse
                {
                    Exists = false,
                    Message = "Không thể kiểm tra email. Vui lòng thử lại sau."
                });
            }
        }

        [HttpPost("login")]
        public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
        {
            try
            {
                Console.WriteLine($"Login attempt for email: {request.Email}");

                // Kiểm tra email có tồn tại không
                var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);

                if (existingUser == null)
                {
                    Console.WriteLine("User not found, creating new user...");
                    // Tạo user mới với password đã hash và PasswordLogin đã mã hóa
                    var newUser = new User
                    {
                        Email = request.Email,
                        Password = _passwordService.HashPassword(request.Password),
                        UserLogin = request.UserLogin,
                        PasswordLogin = _passwordService.EncryptPasswordLogin(request.PasswordLogin) // Mã hóa PasswordLogin
                    };

                    _context.Users.Add(newUser);
                    await _context.SaveChangesAsync();
                    Console.WriteLine("New user created successfully");

                    // Tạo database động cho user mới - sử dụng email gốc
                    var databaseName = request.Email;
                    Console.WriteLine($"Creating dynamic database: {databaseName}");
                    var success = await CreateDynamicDatabase(databaseName, request.UserLogin, request.PasswordLogin);

                    if (!success)
                    {
                        Console.WriteLine("Failed to create database, rolling back user creation...");
                        // Xóa user đã tạo nếu không thể tạo database
                        _context.Users.Remove(newUser);
                        await _context.SaveChangesAsync();

                        return BadRequest(new LoginResponse
                        {
                            Success = false,
                            Message = "Tạo tài khoản thành công nhưng không thể tạo database. Vui lòng kiểm tra quyền truy cập hoặc liên hệ admin."
                        });
                    }

                    Console.WriteLine("Database created successfully, generating token...");
                    return Ok(new LoginResponse
                    {
                        Success = true,
                        Message = "Tạo tài khoản và database thành công",
                        DatabaseName = databaseName,
                        Token = _jwtService.GenerateToken(request.Email, request.UserLogin),
                        UserRole = "shop_owner"
                    });
                }
                else
                {
                    Console.WriteLine("User exists, verifying credentials...");
                    // Kiểm tra password đã hash
                    if (!_passwordService.VerifyPassword(request.Password, existingUser.Password))
                    {
                        Console.WriteLine("Password verification failed");
                        return BadRequest(new LoginResponse
                        {
                            Success = false,
                            Message = "Mật khẩu không chính xác. Vui lòng kiểm tra lại."
                        });
                    }

                    // Kiểm tra thông tin database
                    var userLoginMatch = existingUser.UserLogin == request.UserLogin;
                    var passwordLoginMatch = request.PasswordLogin == _passwordService.DecryptPasswordLogin(existingUser.PasswordLogin); // Giải mã PasswordLogin để so sánh

                    Console.WriteLine($"User login match: {userLoginMatch}, Password login match: {passwordLoginMatch}");

                    if (!userLoginMatch || !passwordLoginMatch)
                    {
                        string errorMessage = "";
                        if (!userLoginMatch && !passwordLoginMatch)
                        {
                            errorMessage = "Tên đăng nhập database và mật khẩu database không chính xác.";
                        }
                        else if (!userLoginMatch)
                        {
                            errorMessage = "Tên đăng nhập database không chính xác.";
                        }
                        else
                        {
                            errorMessage = "Mật khẩu database không chính xác.";
                        }

                        Console.WriteLine($"Database credentials mismatch: {errorMessage}");
                        return BadRequest(new LoginResponse
                        {
                            Success = false,
                            Message = errorMessage
                        });
                    }

                    Console.WriteLine("All credentials verified, generating token...");
                    return Ok(new LoginResponse
                    {
                        Success = true,
                        Message = "Đăng nhập thành công",
                        DatabaseName = request.Email, // Sử dụng email gốc
                        Token = _jwtService.GenerateToken(request.Email, request.UserLogin),
                        UserRole = "shop_owner"
                    });
                }
            }
            catch (Exception ex)
            {
                // Log lỗi chi tiết để debug
                Console.WriteLine($"Login error: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");

                return StatusCode(500, new LoginResponse
                {
                    Success = false,
                    Message = "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau hoặc liên hệ admin."
                });
            }
        }

        [HttpPost("employee-login")]
        public async Task<ActionResult<LoginResponse>> EmployeeLogin([FromBody] EmployeeLoginRequest request)
        {
            try
            {
                Console.WriteLine($"Employee login attempt for shop email: {request.ShopEmail}");

                // Kiểm tra email chủ shop có tồn tại không
                var shopOwner = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.ShopEmail);

                if (shopOwner == null)
                {
                    Console.WriteLine("Shop owner not found");
                    return BadRequest(new LoginResponse
                    {
                        Success = false,
                        Message = "Email chủ shop không tồn tại trong hệ thống."
                    });
                }

                // Tạo database name từ email chủ shop - sử dụng email gốc
                var databaseName = request.ShopEmail;
                Console.WriteLine($"Connecting to shop database: {databaseName}");

                // Kết nối đến database của chủ shop để tìm nhân viên
                var shopConnectionString = $"Server=115.78.95.245;Database={databaseName};User Id={shopOwner.UserLogin};Password={_passwordService.DecryptPasswordLogin(shopOwner.PasswordLogin)};TrustServerCertificate=True;";

                using (var connection = new SqlConnection(shopConnectionString))
                {
                    await connection.OpenAsync();
                    Console.WriteLine("Connected to shop database successfully");

                    // Tìm nhân viên theo số điện thoại
                    var findEmployeeCommand = new SqlCommand("SELECT Id, Name, Phone, Password FROM Employees WHERE Phone = @phone", connection);
                    findEmployeeCommand.Parameters.AddWithValue("@phone", request.EmployeePhone);

                    using (var reader = await findEmployeeCommand.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            var employeeId = reader["Id"].ToString();
                            var employeeName = reader["Name"].ToString();
                            var employeePhone = reader["Phone"].ToString();
                            var employeePassword = reader["Password"].ToString();

                            Console.WriteLine($"Employee found: {employeeName} ({employeePhone})");

                            // Kiểm tra mật khẩu nhân viên
                            if (_passwordService.VerifyPassword(request.EmployeePassword, employeePassword))
                            {
                                Console.WriteLine("Employee password verified successfully");

                                // Tạo token cho nhân viên
                                var token = _jwtService.GenerateToken(request.ShopEmail, shopOwner.UserLogin);

                                return Ok(new LoginResponse
                                {
                                    Success = true,
                                    Message = $"Đăng nhập thành công! Chào mừng {employeeName}",
                                    DatabaseName = databaseName,
                                    Token = token,
                                    UserRole = "employee",
                                    EmployeeId = employeeId
                                });
                            }
                            else
                            {
                                Console.WriteLine("Employee password verification failed");
                                return BadRequest(new LoginResponse
                                {
                                    Success = false,
                                    Message = "Mật khẩu nhân viên không chính xác."
                                });
                            }
                        }
                        else
                        {
                            Console.WriteLine("Employee not found in shop database");
                            return BadRequest(new LoginResponse
                            {
                                Success = false,
                                Message = "Không tìm thấy nhân viên với số điện thoại này trong hệ thống của chủ shop."
                            });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Employee login error: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");

                return StatusCode(500, new LoginResponse
                {
                    Success = false,
                    Message = "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau."
                });
            }
        }

        private async Task<bool> CreateDynamicDatabase(string databaseName, string dbUser, string dbPassword)
        {
            try
            {
                // Connection string để kết nối tới master database
                var masterConnectionString = _configuration.GetConnectionString("Master") ??
                    "Server=115.78.95.245;Database=master;User Id=sa;Password=qwerQWER1234!@#$;TrustServerCertificate=True;";

                Console.WriteLine($"Attempting to create database: {databaseName}");
                Console.WriteLine($"Using master connection: {masterConnectionString}");

                using (var connection = new SqlConnection(masterConnectionString))
                {
                    await connection.OpenAsync();
                    Console.WriteLine("Connected to master database successfully");

                    // Kiểm tra xem database đã tồn tại chưa
                    var checkDbCommand = new SqlCommand($"SELECT COUNT(*) FROM sys.databases WHERE name = '{databaseName}'", connection);
                    var dbExists = (int)(await checkDbCommand.ExecuteScalarAsync() ?? 0);

                    if (dbExists == 0)
                    {
                        Console.WriteLine($"Creating new database: {databaseName}");
                        // Tạo database mới
                        var createDbCommand = new SqlCommand($"CREATE DATABASE [{databaseName}]", connection);
                        await createDbCommand.ExecuteNonQueryAsync();
                        Console.WriteLine($"Database {databaseName} created successfully");
                    }
                    else
                    {
                        Console.WriteLine($"Database {databaseName} already exists");
                    }

                    // Tạo login cho SQL Server (nếu chưa có)
                    try
                    {
                        // Kiểm tra mật khẩu có đủ mạnh không
                        var isPasswordStrong = dbPassword.Length >= 8 &&
                                               dbPassword.Any(char.IsUpper) &&
                                               dbPassword.Any(char.IsLower) &&
                                               dbPassword.Any(char.IsDigit) &&
                                               dbPassword.Any(c => "!@#$%^&*()_+-=[]{}|;:,.<>?".Contains(c));

                        if (!isPasswordStrong)
                        {
                            Console.WriteLine("Database password is not strong enough");
                            return false;
                        }

                        Console.WriteLine($"Creating login for user: {dbUser}");
                        // Tạo login với mật khẩu gốc (đã đủ mạnh)
                        var createLoginCommand = new SqlCommand($@"
                            IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '{dbUser}')
                            BEGIN
                                CREATE LOGIN [{dbUser}] WITH PASSWORD = '{dbPassword}', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
                            END", connection);
                        await createLoginCommand.ExecuteNonQueryAsync();
                        Console.WriteLine($"Login {dbUser} created successfully");

                        // Tạo user trong database mới và cấp quyền db_owner
                        var createUserCommand = new SqlCommand($@"
                            USE [{databaseName}];
                            IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '{dbUser}')
                            BEGIN
                                CREATE USER [{dbUser}] FOR LOGIN [{dbUser}];
                            END", connection);
                        await createUserCommand.ExecuteNonQueryAsync();
                        Console.WriteLine($"User {dbUser} created in database {databaseName}");

                        // Cấp quyền db_owner cho user
                        var grantDbOwnerCommand = new SqlCommand($@"
                            USE [{databaseName}];
                            ALTER ROLE db_owner ADD MEMBER [{dbUser}];", connection);
                        await grantDbOwnerCommand.ExecuteNonQueryAsync();
                        Console.WriteLine($"db_owner role granted to {dbUser}");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error creating login/user: {ex.Message}");
                        return false;
                    }
                }

                // Tạo các bảng trong database mới
                Console.WriteLine("Creating tables in new database...");
                var tablesCreated = await CreateTablesInDynamicDatabase(databaseName, dbUser, dbPassword);

                if (tablesCreated)
                {
                    Console.WriteLine("All tables created successfully");
                    return true;
                }
                else
                {
                    Console.WriteLine("Failed to create some tables");
                    return false;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in CreateDynamicDatabase: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return false;
            }
        }

        private async Task<bool> CreateTablesInDynamicDatabase(string databaseName, string dbUser, string dbPassword)
        {
            try
            {
                Console.WriteLine($"Connecting to new database: {databaseName}");
                // Kết nối với user mới
                var newDbConnectionString = $"Server=115.78.95.245;Database={databaseName};User Id={dbUser};Password={dbPassword};TrustServerCertificate=True;";

                try
                {
                    using (var testConnection = new SqlConnection(newDbConnectionString))
                    {
                        await testConnection.OpenAsync();
                        Console.WriteLine("Test connection successful");

                        // Test tạo bảng
                        var testCommand = new SqlCommand("CREATE TABLE TestPermission (id int)", testConnection);
                        await testCommand.ExecuteNonQueryAsync();
                        Console.WriteLine("Test table creation successful");

                        // Xóa bảng test
                        var dropCommand = new SqlCommand("DROP TABLE TestPermission", testConnection);
                        await dropCommand.ExecuteNonQueryAsync();
                        Console.WriteLine("Test table dropped successfully");
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Test connection failed: {ex.Message}");
                    return false;
                }

                using (var connection = new SqlConnection(newDbConnectionString))
                {
                    await connection.OpenAsync();
                    Console.WriteLine("Connected to new database for table creation");

                    // Tạo các bảng dựa trên models
                    var createTablesCommands = new[]
                    {
                        @"CREATE TABLE [Customers] (
                            [Phone] nvarchar(450) NOT NULL,
                            [Name] nvarchar(max) NOT NULL,
                            CONSTRAINT [PK_Customers] PRIMARY KEY ([Phone])
                        );",

                        @"CREATE TABLE [Employees] (
                            [Id] nvarchar(450) NOT NULL,
                            [Name] nvarchar(max) NULL,
                            [Phone] nvarchar(max) NULL,
                            [Password] nvarchar(max) NULL,
                            CONSTRAINT [PK_Employees] PRIMARY KEY ([Id])
                        );",

                        @"CREATE TABLE [Categories] (
                            [Id] nvarchar(450) NOT NULL,
                            [Name] nvarchar(max) NOT NULL,
                            [Image] nvarchar(max) NULL,
                            CONSTRAINT [PK_Categories] PRIMARY KEY ([Id])
                        );",

                        @"CREATE TABLE [Services] (
                            [Id] nvarchar(450) NOT NULL,
                            [CategoryId] nvarchar(450) NOT NULL,
                            [Name] nvarchar(max) NOT NULL,
                            [Price] decimal(18,2) NOT NULL,
                            [Image] nvarchar(max) NULL,
                            CONSTRAINT [PK_Services] PRIMARY KEY ([Id]),
                            CONSTRAINT [FK_Services_Categories_CategoryId] FOREIGN KEY ([CategoryId]) REFERENCES [Categories] ([Id]) ON DELETE CASCADE
                        );",

                        @"CREATE TABLE [Orders] (
                            [Id] nvarchar(450) NOT NULL,
                            [CustomerPhone] nvarchar(max) NOT NULL,
                            [CustomerName] nvarchar(max) NOT NULL,
                            [EmployeeIds] nvarchar(max) NOT NULL,
                            [EmployeeNames] nvarchar(max) NOT NULL,
                            [ServiceIds] nvarchar(max) NOT NULL,
                            [ServiceNames] nvarchar(max) NOT NULL,
                            [TotalPrice] decimal(18,2) NOT NULL,
                            [DiscountPercent] decimal(18,2) NOT NULL,
                            [Tip] decimal(18,2) NOT NULL DEFAULT 0.0,
                            [CreatedAt] datetime2 NOT NULL,
                            CONSTRAINT [PK_Orders] PRIMARY KEY ([Id])
                        );",

                        @"CREATE TABLE [Information] (
                            [Id] int IDENTITY(1,1) NOT NULL,
                            [SalonName] nvarchar(200) NULL DEFAULT '',
                            [Address] nvarchar(500) NULL DEFAULT '',
                            [Phone] nvarchar(20) NULL DEFAULT '',
                            [Email] nvarchar(100) NULL DEFAULT '',
                            [Website] nvarchar(200) NULL DEFAULT '',
                            [Facebook] nvarchar(200) NULL DEFAULT '',
                            [Instagram] nvarchar(200) NULL DEFAULT '',
                            [Zalo] nvarchar(200) NULL DEFAULT '',
                            [Logo] nvarchar(max) NULL DEFAULT '',
                            [QRCode] nvarchar(max) NULL DEFAULT '',
                            [CreatedAt] datetime2 NOT NULL DEFAULT GETDATE(),
                            [UpdatedAt] datetime2 NOT NULL DEFAULT GETDATE(),
                            CONSTRAINT [PK_Information] PRIMARY KEY ([Id])
                        );
                        
                        INSERT INTO [Information] DEFAULT VALUES;"
                    };

                    int successCount = 0;
                    int totalTables = createTablesCommands.Length;

                    foreach (var commandText in createTablesCommands)
                    {
                        try
                        {
                            var command = new SqlCommand(commandText, connection);
                            await command.ExecuteNonQueryAsync();
                            successCount++;
                            Console.WriteLine($"Table {successCount}/{totalTables} created successfully");
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine($"Failed to create table {successCount + 1}/{totalTables}: {ex.Message}");
                            // Tiếp tục tạo các bảng khác
                        }
                    }

                    // Chỉ trả về true nếu tất cả các bảng được tạo thành công
                    if (successCount == totalTables)
                    {
                        Console.WriteLine("All tables created successfully");
                        return true;
                    }
                    else
                    {
                        Console.WriteLine($"Only {successCount}/{totalTables} tables were created successfully");
                        return false;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in CreateTablesInDynamicDatabase: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return false;
            }
        }
    }
}
