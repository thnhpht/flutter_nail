using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Category")]
    public class Category
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; } = string.Empty;
        public string? Image { get; set; } // URL or path to image
        public ICollection<Service> Items { get; set; } = new List<Service>();
    }
}