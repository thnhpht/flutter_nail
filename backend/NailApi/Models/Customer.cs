using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Customers")]
    public class Customer
    {
        public string Phone { get; set; } = string.Empty; // PK
        public string Name { get; set; } = string.Empty;
        
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Code { get; set; } // Auto-increment code
        
        public string? Address { get; set; } // Optional address
        public string? Group { get; set; } // Optional group
    }
}