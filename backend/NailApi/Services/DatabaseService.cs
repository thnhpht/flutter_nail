using Microsoft.Data.SqlClient;
using NailApi.Data;
using Microsoft.EntityFrameworkCore;

namespace NailApi.Services
{
    public interface IDatabaseService
    {
        Task<DynamicDbContext> GetDynamicDbContextAsync(string email, string userLogin, string passwordLogin);
        Task<bool> TestConnectionAsync(string databaseName, string userLogin, string passwordLogin);
    }

    public class DatabaseService : IDatabaseService
    {
        private readonly IConfiguration _configuration;
        private readonly AppDbContext _nailAdminContext;
        private readonly IPasswordService _passwordService;

        public DatabaseService(IConfiguration configuration, AppDbContext nailAdminContext, IPasswordService passwordService)
        {
            _configuration = configuration;
            _nailAdminContext = nailAdminContext;
            _passwordService = passwordService;
        }

        public async Task<DynamicDbContext> GetDynamicDbContextAsync(string email, string userLogin, string passwordLogin)
        {
            // Nếu passwordLogin rỗng, lấy từ database NailAdmin
            if (string.IsNullOrEmpty(passwordLogin))
            {
                try
                {
                    var user = await _nailAdminContext.Users.FirstOrDefaultAsync(u => u.Email == email);
                    if (user != null)
                    {
                        // Lấy passwordLogin từ database (đã được mã hóa) và giải mã
                        passwordLogin = _passwordService.DecryptPasswordLogin(user.PasswordLogin);
                    }
                }
                catch (Exception ex)
                {
                    throw new Exception($"Không thể lấy thông tin đăng nhập database: {ex.Message}");
                }
            }

            if (string.IsNullOrEmpty(passwordLogin))
            {
                throw new Exception("Không thể xác định mật khẩu database. Vui lòng đăng nhập lại.");
            }

            // Sử dụng cùng logic tạo database name như trong AuthController
            var databaseName = email.Replace("@", "_").Replace(".", "_");
            var connectionString = $"Server=115.78.95.245;Database={databaseName};User Id={userLogin};Password={passwordLogin};TrustServerCertificate=True;";
            
            return new DynamicDbContext(connectionString);
        }

        public async Task<bool> TestConnectionAsync(string databaseName, string userLogin, string passwordLogin)
        {
            try
            {
                var connectionString = $"Server=115.78.95.245;Database={databaseName};User Id={userLogin};Password={passwordLogin};TrustServerCertificate=True;";
                
                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    return true;
                }
            }
            catch
            {
                return false;
            }
        }
    }
}
