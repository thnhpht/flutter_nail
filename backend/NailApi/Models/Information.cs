using System.ComponentModel.DataAnnotations;

namespace NailApi.Models
{
    public class Information
    {
        [Key]
        public int Id { get; set; }

        [MaxLength(200)]
        public string SalonName { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string Address { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string Phone { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string Email { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string Website { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string Facebook { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string Instagram { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string Zalo { get; set; } = string.Empty;
        
        public string Logo { get; set; } = string.Empty; // Base64 encoded image or URL (nvarchar(max))
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
