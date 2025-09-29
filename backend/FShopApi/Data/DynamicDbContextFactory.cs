using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace FShopApi.Data
{
    public class DynamicDbContextFactory : IDesignTimeDbContextFactory<DynamicDbContext>
    {
        public DynamicDbContext CreateDbContext(string[] args)
        {
            // Sử dụng connection string mặc định cho design time
            var connectionString = "Server=115.78.95.245;Database=aeri_gmail_com;User Id=sa;Password=qwerQWER1234!@#$;TrustServerCertificate=True;";
            
            var optionsBuilder = new DbContextOptionsBuilder<DynamicDbContext>();
            optionsBuilder.UseSqlServer(connectionString, sqlOptions =>
            {
                sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,
                    maxRetryDelay: TimeSpan.FromSeconds(30),
                    errorNumbersToAdd: null);
                sqlOptions.CommandTimeout(60);
            });

            return new DynamicDbContext(connectionString);
        }
    }
}
