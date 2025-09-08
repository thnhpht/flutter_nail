using System.ComponentModel.DataAnnotations;

namespace NailApi.Models
{
    public class EmployeeLoginRequest
    {
        [Required]
        [EmailAddress]
        public string ShopEmail { get; set; } = string.Empty;

        [Required]
        public string EmployeePhone { get; set; } = string.Empty;

        [Required]
        public string EmployeePassword { get; set; } = string.Empty;
    }
}
