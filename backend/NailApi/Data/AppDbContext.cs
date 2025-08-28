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
        public DbSet<Service> Services => Set<Service>();
        public DbSet<Order> Orders => Set<Order>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Customer>().HasKey(c => c.Phone);

            modelBuilder.Entity<Customer>()
                .Property(c => c.Phone)
                .IsRequired();

            modelBuilder.Entity<Employee>()
                .Property(e => e.Id)
                .HasDefaultValueSql("NEWID()");

            modelBuilder.Entity<Category>()
                .Property(c => c.Id)
                .HasDefaultValueSql("NEWID()");

            modelBuilder.Entity<Service>()
                .Property(s => s.Id)
                .HasDefaultValueSql("NEWID()");

            modelBuilder.Entity<Service>()
                .HasOne(s => s.Category)
                .WithMany(c => c.Items)
                .HasForeignKey(s => s.CategoryId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Order>()
                .Property(o => o.Id)
                .HasDefaultValueSql("NEWID()");
        }
    }
}