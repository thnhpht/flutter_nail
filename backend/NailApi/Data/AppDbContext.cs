using Microsoft.EntityFrameworkCore;
using NailApi.Models;

namespace NailApi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Customer> Customers => Set<Customer>();
        public DbSet<Employee> Employees => Set<Employee>();
        public DbSet<Category> Categories => Set<Category>();
        public DbSet<CategoryItem> CategoryItems => Set<CategoryItem>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Customer>().HasKey(c => c.PhoneNumber);

            modelBuilder.Entity<Customer>()
                .Property(c => c.PhoneNumber)
                .IsRequired();

            modelBuilder.Entity<Employee>()
                .Property(e => e.Id)
                .ValueGeneratedOnAdd();

            modelBuilder.Entity<Category>()
                .Property(c => c.Id)
                .ValueGeneratedOnAdd();

            modelBuilder.Entity<CategoryItem>()
                .Property(ci => ci.Id)
                .ValueGeneratedOnAdd();

            modelBuilder.Entity<CategoryItem>()
                .HasOne(ci => ci.Category)
                .WithMany(c => c.Items)
                .HasForeignKey(ci => ci.CategoryId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}