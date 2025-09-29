using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace FShopApi.Models
{
    [Table("Services")]
    public class Service
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string CategoryId { get; set; } = string.Empty; // Remove nullable since DB doesn't allow NULL
        public string Name { get; set; } = string.Empty;
        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }
        public string? Image { get; set; } // URL or path to image
        
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Code { get; set; } // Auto-increment code
        
        public string? Unit { get; set; } // Unit of measurement (optional)
        
        [JsonIgnore]
        public Category? Category { get; set; }
    }
}
