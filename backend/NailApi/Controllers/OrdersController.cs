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

        /// <summary>
        /// Format order ID to first 8 characters in uppercase
        /// </summary>
        private static string FormatOrderId(string orderId)
        {
            return orderId.Length > 8 
                ? orderId.Substring(0, 8).ToUpper()
                : orderId.ToUpper();
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
                    Message = $"Nhân viên {employeeName} đã tạo đơn mới #{FormatOrderId(input.Id)} cho khách hàng {input.CustomerName} ({input.CustomerPhone}) với tổng tiền {input.TotalPrice:N0} VNĐ",
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
                
                // Check if delivery status changed to "delivered"
                bool deliveryStatusChanged = exists.DeliveryStatus != "delivered" && input.DeliveryStatus == "delivered";
                
                dbContext.Entry(exists).CurrentValues.SetValues(input);
                await dbContext.SaveChangesAsync();
                
                // Create notification if delivery status changed to "delivered"
                if (deliveryStatusChanged)
                {
                    var notificationId = Guid.NewGuid().ToString();
                    var employeeName = User.FindFirst("employee_name")?.Value ?? User.FindFirst(ClaimTypes.Name)?.Value;
                    var deliveredAt = DateTime.Now;
                    
                    var notificationData = JsonSerializer.Serialize(new
                    {
                        orderId = input.Id,
                        customerName = input.CustomerName,
                        customerAddress = input.CustomerAddress,
                        employeeName = employeeName,
                        deliveredAt = deliveredAt.ToString("yyyy-MM-ddTHH:mm:ss")
                    });

                    var notification = new Notification
                    {
                        Id = notificationId,
                        Title = "Đơn hàng đã được giao",
                        Message = $"Nhân viên {employeeName} đã giao đơn hàng #{FormatOrderId(input.Id)} cho khách hàng {input.CustomerName} tại địa chỉ {input.CustomerAddress} lúc {deliveredAt:dd/MM/yyyy HH:mm}",
                        Type = "order_delivered",
                        CreatedAt = deliveredAt,
                        IsRead = false,
                        Data = notificationData
                    };

                    dbContext.Notifications.Add(notification);
                    await dbContext.SaveChangesAsync();
                    Console.WriteLine($"Order delivered notification created with ID: {notificationId}");
                }
                
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

        // POST: api/orders/upload-delivery-image
        [HttpPost("upload-delivery-image")]
        public async Task<ActionResult<string>> UploadDeliveryImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest("No file uploaded");
            }

            // Kiểm tra kích thước file (max 5MB)
            if (file.Length > 5 * 1024 * 1024)
            {
                return BadRequest("File size too large. Maximum 5MB allowed.");
            }

            // Kiểm tra loại file
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
            var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!allowedExtensions.Contains(fileExtension))
            {
                return BadRequest("Invalid file type. Only JPG, PNG, GIF, and WebP are allowed.");
            }

            try
            {
                // Đọc file thành byte array
                using var memoryStream = new MemoryStream();
                await file.CopyToAsync(memoryStream);
                var fileBytes = memoryStream.ToArray();

                // Convert thành base64 string
                var base64String = Convert.ToBase64String(fileBytes);
                var dataUrl = $"data:image/{fileExtension.Substring(1)};base64,{base64String}";

                return Ok(new { imageUrl = dataUrl });
            }
            catch (Exception ex)
            {
                return BadRequest($"Error uploading image: {ex.Message}");
            }
        }
    }
}
