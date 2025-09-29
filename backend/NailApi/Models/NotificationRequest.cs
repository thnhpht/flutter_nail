namespace NailApi.Models
{
    public class NotificationRequest
    {
        public string ShopName { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string OrderId { get; set; } = string.Empty;
        public string CustomerName { get; set; } = string.Empty;
        public string CustomerPhone { get; set; } = string.Empty;
        public string EmployeeName { get; set; } = string.Empty;
        public decimal TotalPrice { get; set; }
    }
}
