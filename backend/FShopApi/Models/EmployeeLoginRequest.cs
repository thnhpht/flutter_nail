using System.ComponentModel.DataAnnotations;

namespace FShopApi.Models
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
