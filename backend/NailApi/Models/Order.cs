using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Order")]
    public class Order
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string CustomerPhone { get; set; } = string.Empty;
        public string CustomerName { get; set; } = string.Empty;
        public Guid EmployeeId { get; set; }
        public string EmployeeName { get; set; } = string.Empty;
        public string CategoryIds { get; set; } = string.Empty; // JSON array of category IDs
        public string CategoryName { get; set; } = string.Empty;
        public string ServiceIds { get; set; } = string.Empty; // JSON array of service IDs
        public string ServiceNames { get; set; } = string.Empty; // JSON array of service names
        public double TotalPrice { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
