using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace NailApi.Models
{
    [Table("Service")]
    public class Service
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string? CategoryId { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int DurationMin { get; set; }
        [JsonIgnore]
        public Category? Category { get; set; }
    }
}