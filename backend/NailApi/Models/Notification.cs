using System.ComponentModel.DataAnnotations;

namespace NailApi.Models
{
    public class Notification
    {
        [Key]
        public string Id { get; set; } = string.Empty;
        
        [Required]
        public string Title { get; set; } = string.Empty;
        
        [Required]
        public string Message { get; set; } = string.Empty;
        
        [Required]
        public string Type { get; set; } = string.Empty;
        
        public DateTime CreatedAt { get; set; }
        
        public bool IsRead { get; set; }
        
        public string? Data { get; set; }
    }
}
