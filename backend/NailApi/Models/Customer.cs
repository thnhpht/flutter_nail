using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Customers")]
    public class Customer
    {
        public string Phone { get; set; } = string.Empty; // PK
        public string Name { get; set; } = string.Empty;
    }
}