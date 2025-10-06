using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NailApi.Data;
using NailApi.Models;
using NailApi.Services;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using System.Text.Json;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class OrdersController : ControllerBase
    {
        private readonly IDatabaseService _databaseService;

        public OrdersController(IDatabaseService databaseService)
        {
            _databaseService = databaseService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Order>>> GetAll()
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                return await dbContext.Orders.AsNoTracking().ToListAsync();
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Order>> GetById(string id)
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var entity = await dbContext.Orders.FindAsync(id);
                if (entity == null) return NotFound();
                return entity;
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<Order>> Create(Order input)
        {
            if (string.IsNullOrWhiteSpace(input.CustomerPhone))
                return BadRequest("CustomerPhone is required");

            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                dbContext.Orders.Add(input);
                await dbContext.SaveChangesAsync();

                // Create notification for order created by employee
                var notificationId = Guid.NewGuid().ToString();
                var employeeName = User.FindFirst("employee_name")?.Value ?? User.FindFirst(ClaimTypes.Name)?.Value;
                var notificationData = JsonSerializer.Serialize(new
                {
                    orderId = input.Id,
                    customerName = input.CustomerName,
                    customerPhone = input.CustomerPhone,
                    employeeName = employeeName,
                    totalPrice = input.TotalPrice
                });

                var notification = new Notification
                {
                    Id = notificationId,
                    Title = "Đơn hàng mới",
                    Message = $"Nhân viên {employeeName} đã tạo đơn cho khách hàng {input.CustomerName} ({input.CustomerPhone}) với tổng tiền {input.TotalPrice:N0} VNĐ",
                    Type = "order_created",
                    CreatedAt = DateTime.Now,
                    IsRead = false,
                    Data = notificationData
                };

                dbContext.Notifications.Add(notification);
                await dbContext.SaveChangesAsync();
                Console.WriteLine($"Order notification created with ID: {notificationId}");

                return CreatedAtAction(nameof(GetById), new { id = input.Id }, input);
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, Order input)
        {
            if (id != input.Id) return BadRequest("Id mismatch");
            
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var exists = await dbContext.Orders.FindAsync(id);
                if (exists == null) return NotFound();
                dbContext.Entry(exists).CurrentValues.SetValues(input);
                await dbContext.SaveChangesAsync();
                return NoContent();
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var entity = await dbContext.Orders.FindAsync(id);
                if (entity == null) return NotFound();
                dbContext.Orders.Remove(entity);
                await dbContext.SaveChangesAsync();
                return NoContent();
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpGet("customer/{customerPhone}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetByCustomer(string customerPhone)
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var orders = await dbContext.Orders.Where(o => o.CustomerPhone == customerPhone).ToListAsync();
                return orders;
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpGet("date-range")]
        public async Task<ActionResult<IEnumerable<Order>>> GetByDateRange([FromQuery] DateTime startDate, [FromQuery] DateTime endDate, [FromQuery] string email, [FromQuery] string userLogin, [FromQuery] string passwordLogin)
        {
            try
            {
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, passwordLogin);
                var orders = await dbContext.Orders
                    .Where(o => o.CreatedAt >= startDate && o.CreatedAt <= endDate)
                    .ToListAsync();
                return orders;
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpGet("total-revenue")]
        public async Task<ActionResult<object>> GetTotalRevenue([FromQuery] DateTime startDate, [FromQuery] DateTime endDate, [FromQuery] string email, [FromQuery] string userLogin, [FromQuery] string passwordLogin)
        {
            try
            {
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, passwordLogin);
                var totalRevenue = await dbContext.Orders
                    .Where(o => o.CreatedAt >= startDate && o.CreatedAt <= endDate)
                    .SumAsync(o => o.TotalPrice);
                
                var totalOrders = await dbContext.Orders
                    .Where(o => o.CreatedAt >= startDate && o.CreatedAt <= endDate)
                    .CountAsync();

                return new { totalRevenue, totalOrders, startDate, endDate };
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }
    }
}
