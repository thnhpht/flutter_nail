namespace NailApi.Models
{
    public class MarkNotificationReadRequest
    {
        public string ShopEmail { get; set; } = string.Empty;
        public string NotificationId { get; set; } = string.Empty;
    }
}
