using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Orders")]
    public class Order
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string CustomerPhone { get; set; } = string.Empty;
        public string CustomerName { get; set; } = string.Empty;
        public string EmployeeIds { get; set; } = string.Empty;
        public string EmployeeNames { get; set; } = string.Empty;
        public string ServiceIds { get; set; } = string.Empty;
        public string ServiceNames { get; set; } = string.Empty;
        public decimal TotalPrice { get; set; }
        public decimal DiscountPercent { get; set; } = 0.0M;
        public decimal Tip { get; set; } = 0.0M;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
