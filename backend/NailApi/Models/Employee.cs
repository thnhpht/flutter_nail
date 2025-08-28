using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Employee")]
    public class Employee
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; } = string.Empty;
        public string? Phone { get; set; }
    }
}