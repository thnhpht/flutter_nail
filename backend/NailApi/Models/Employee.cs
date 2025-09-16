using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Employees")]
    public class Employee
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Name { get; set; } = string.Empty;
        public string? Phone { get; set; }
        [System.ComponentModel.DataAnnotations.Required(AllowEmptyStrings = true)]
        public string? Password { get; set; }
    }
}
