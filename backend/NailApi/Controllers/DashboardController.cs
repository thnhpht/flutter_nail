using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NailApi.Data;
using NailApi.Services;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DashboardController : ControllerBase
    {
        private readonly IDatabaseService _databaseService;

        public DashboardController(IDatabaseService databaseService)
        {
            _databaseService = databaseService;
        }

        [HttpGet("today-stats")]
        public async Task<ActionResult<object>> GetTodayStats()
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                
                // Lấy ngày hôm nay
                var today = DateTime.Today;
                var tomorrow = today.AddDays(1);
                
                // Đếm số hóa đơn hôm nay
                var totalBills = await dbContext.Orders
                    .Where(o => o.CreatedAt >= today && o.CreatedAt < tomorrow)
                    .CountAsync();
                
                // Đếm số khách hàng duy nhất hôm nay (khách hàng có ít nhất 1 hóa đơn trong ngày)
                var todayCustomers = await dbContext.Orders
                    .Where(o => o.CreatedAt >= today && o.CreatedAt < tomorrow)
                    .Select(o => o.CustomerPhone)
                    .Distinct()
                    .CountAsync();
                
                // Tính tổng doanh thu hôm nay
                var totalRevenue = await dbContext.Orders
                    .Where(o => o.CreatedAt >= today && o.CreatedAt < tomorrow)
                    .SumAsync(o => o.TotalPrice);
                
                return Ok(new
                {
                    totalBills = totalBills,
                    totalCustomers = todayCustomers,
                    totalRevenue = totalRevenue
                });
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }
    }
}
