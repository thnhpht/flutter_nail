using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Category")]
    public class Category
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public ICollection<Service> Items { get; set; } = new List<Service>();
    }
}