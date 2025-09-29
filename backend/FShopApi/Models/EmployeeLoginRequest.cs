using System.ComponentModel.DataAnnotations;

namespace NailApi.Models
{
    public class EmployeeLoginRequest
    {
        [Required]
        public string ShopName { get; set; } = string.Empty;

        [Required]
        public string EmployeePhone { get; set; } = string.Empty;

        [Required]
        public string EmployeePassword { get; set; } = string.Empty;
    }
}
