using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace FShopApi.Models
{
    [Table("Categories")]
    public class Category
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Name { get; set; } = string.Empty;
        public string? Image { get; set; } // URL or path to image
        public ICollection<Service> Services { get; set; } = new List<Service>();
    }
}