using System.Collections.Generic;

namespace NailApi.Models
{
    public class Category
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public ICollection<CategoryItem> Items { get; set; } = new List<CategoryItem>();
    }
}