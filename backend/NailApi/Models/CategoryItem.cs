namespace NailApi.Models
{
    public class CategoryItem
    {
        public int Id { get; set; }
        public int CategoryId { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public Category? Category { get; set; }
    }
}