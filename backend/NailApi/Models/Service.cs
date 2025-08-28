using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace NailApi.Models
{
    [Table("Service")]
    public class Service
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid CategoryId { get; set; } // Remove nullable since DB doesn't allow NULL
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string? Image { get; set; } // URL or path to image
        [JsonIgnore]
        public Category? Category { get; set; }
    }
}