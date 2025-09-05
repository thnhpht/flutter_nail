namespace NailApi.Models
{
    public class CreateStrongLoginRequest
    {
        public string UserLogin { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
    }
}
