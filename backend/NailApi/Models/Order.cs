using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Order")]
    public class Order
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string CustomerPhone { get; set; } = string.Empty;
        public string CustomerName { get; set; } = string.Empty;
        public string EmployeeIds { get; set; } = string.Empty;
        public string EmployeeNames { get; set; } = string.Empty;
        public string ServiceIds { get; set; } = string.Empty;
        public string ServiceNames { get; set; } = string.Empty;
        public double TotalPrice { get; set; }
        public double DiscountPercent { get; set; } = 0.0;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
