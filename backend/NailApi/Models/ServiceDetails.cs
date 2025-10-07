using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace NailApi.Models
{
    [Table("ServiceDetails")]
    public class ServiceDetails
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        
        [Required]
        public int Quantity { get; set; } // Số lượng
        
        [Required]
        [MaxLength(450)]
        public string ServiceId { get; set; } = string.Empty; // Foreign key to Services table
        
        [Required]
        public DateTime ImportDate { get; set; } = DateTime.UtcNow; // Ngày nhập
        
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal ImportPrice { get; set; } // Giá nhập
        
        public string? Notes { get; set; } // Ghi chú (optional)
        
        // Navigation property
        [JsonIgnore]
        public Service? Service { get; set; }
    }
}
