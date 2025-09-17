using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Employees")]
    public class Employee
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        
        [Required(ErrorMessage = "Name is required")]
        public string Name { get; set; } = string.Empty;
        
        public string? Phone { get; set; }
        
        // Password không bắt buộc - có thể null khi update mà không đổi password
        public string? Password { get; set; }
    }
}
