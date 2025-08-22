using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Employee")]
    public class Employee
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Name { get; set; } = string.Empty;
        public string? Phone { get; set; }
    }
}