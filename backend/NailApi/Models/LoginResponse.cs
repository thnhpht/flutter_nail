namespace NailApi.Models
{
    public class LoginResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string DatabaseName { get; set; } = string.Empty;
        public string Token { get; set; } = string.Empty; // Có thể dùng JWT token sau này
        public string? UserRole { get; set; } // 'shop_owner' or 'employee'
        public string? EmployeeId { get; set; } // For employee login
    }
}
