using System.ComponentModel.DataAnnotations.Schema;

namespace NailApi.Models
{
    [Table("Customer")]
    public class Customer
    {
        public string Phone { get; set; } = string.Empty; // PK
        public string Name { get; set; } = string.Empty;
    }
}