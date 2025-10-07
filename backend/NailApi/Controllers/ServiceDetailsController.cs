using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NailApi.Data;
using NailApi.Models;
using NailApi.Services;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ServiceDetailsController : ControllerBase
    {
        private readonly IDatabaseService _databaseService;

        public ServiceDetailsController(IDatabaseService databaseService)
        {
            _databaseService = databaseService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ServiceDetails>>> GetAll()
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                return await dbContext.ServiceDetails
                    .Include(sd => sd.Service)
                    .AsNoTracking()
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ServiceDetails>> GetById(string id)
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var entity = await dbContext.ServiceDetails
                    .Include(sd => sd.Service)
                    .FirstOrDefaultAsync(sd => sd.Id == id);
                
                if (entity == null) return NotFound();
                return entity;
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpGet("by-service/{serviceId}")]
        public async Task<ActionResult<IEnumerable<ServiceDetails>>> GetByServiceId(string serviceId)
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var entities = await dbContext.ServiceDetails
                    .Include(sd => sd.Service)
                    .Where(sd => sd.ServiceId == serviceId)
                    .AsNoTracking()
                    .ToListAsync();
                
                return entities;
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<ServiceDetails>> Create(ServiceDetails input)
        {
            if (string.IsNullOrWhiteSpace(input.ServiceId))
                return BadRequest("ServiceId is required");
            
            if (input.Quantity <= 0)
                return BadRequest("Quantity must be greater than 0");
            
            if (input.ImportPrice < 0)
                return BadRequest("ImportPrice cannot be negative");

            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                
                // Verify that the service exists
                var serviceExists = await dbContext.Services.AnyAsync(s => s.Id == input.ServiceId);
                if (!serviceExists)
                    return BadRequest("Service not found");

                // Ensure Id is properly generated if empty
                if (string.IsNullOrEmpty(input.Id))
                {
                    input.Id = Guid.NewGuid().ToString();
                }

                // Set ImportDate to current time
                input.ImportDate = DateTime.UtcNow;

                dbContext.ServiceDetails.Add(input);
                await dbContext.SaveChangesAsync();
                return CreatedAtAction(nameof(GetById), new { id = input.Id }, input);
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, ServiceDetails input)
        {
            if (id != input.Id) return BadRequest("Id mismatch");
            
            if (string.IsNullOrWhiteSpace(input.ServiceId))
                return BadRequest("ServiceId is required");
            
            if (input.Quantity <= 0)
                return BadRequest("Quantity must be greater than 0");
            
            if (input.ImportPrice < 0)
                return BadRequest("ImportPrice cannot be negative");

            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var exists = await dbContext.ServiceDetails.FindAsync(id);
                if (exists == null) return NotFound();
                
                // Verify that the service exists
                var serviceExists = await dbContext.Services.AnyAsync(s => s.Id == input.ServiceId);
                if (!serviceExists)
                    return BadRequest("Service not found");
                
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
                var entity = await dbContext.ServiceDetails.FindAsync(id);
                if (entity == null) return NotFound();
                dbContext.ServiceDetails.Remove(entity);
                await dbContext.SaveChangesAsync();
                return NoContent();
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpGet("inventory")]
        public async Task<ActionResult<IEnumerable<object>>> GetInventory()
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                
                // Get all services
                var services = await dbContext.Services.ToListAsync();
                
                var inventory = new List<object>();
                
                foreach (var service in services)
                {
                    try
                    {
                        // Calculate total imported quantity
                        var totalImported = await dbContext.ServiceDetails
                            .Where(sd => sd.ServiceId == service.Id)
                            .SumAsync(sd => sd.Quantity);
                        
                        // Calculate total ordered quantity from orders
                        var totalOrdered = 0;
                        var orders = await dbContext.Orders.ToListAsync();
                        foreach (var order in orders)
                        {
                            try
                            {
                                var serviceIds = System.Text.Json.JsonSerializer.Deserialize<List<string>>(order.ServiceIds) ?? new List<string>();
                                var serviceQuantities = System.Text.Json.JsonSerializer.Deserialize<List<int>>(order.ServiceQuantities) ?? new List<int>();
                                
                                for (int i = 0; i < serviceIds.Count && i < serviceQuantities.Count; i++)
                                {
                                    if (serviceIds[i] == service.Id)
                                    {
                                        totalOrdered += serviceQuantities[i];
                                    }
                                }
                            }
                            catch
                            {
                                // Skip orders with invalid JSON
                                continue;
                            }
                        }
                        
                        var remainingQuantity = totalImported - totalOrdered;
                        var isOutOfStock = remainingQuantity <= 0;
                        
                        inventory.Add(new
                        {
                            serviceId = service.Id,
                            totalImported = totalImported,
                            totalOrdered = totalOrdered,
                            remainingQuantity = remainingQuantity,
                            isOutOfStock = isOutOfStock
                        });
                    }
                    catch (Exception)
                    {
                        // If individual service calculation fails, add default values
                        inventory.Add(new
                        {
                            serviceId = service.Id,
                            totalImported = 0,
                            totalOrdered = 0,
                            remainingQuantity = 0,
                            isOutOfStock = true
                        });
                    }
                }
                
                return Ok(inventory);
            }
            catch (Exception)
            {
                // Return empty inventory list instead of error to prevent blocking services
                return Ok(new List<object>());
            }
        }

        [HttpGet("inventory/{serviceId}")]
        public async Task<ActionResult<object>> GetInventoryByServiceId(string serviceId)
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");

                // Check if service exists
                var service = await dbContext.Services.FirstOrDefaultAsync(s => s.Id == serviceId);
                if (service == null)
                    return NotFound("Service not found");

                // Calculate total imported quantity
                var totalImported = await dbContext.ServiceDetails
                    .Where(sd => sd.ServiceId == serviceId)
                    .SumAsync(sd => sd.Quantity);
                
                // Calculate total ordered quantity from orders
                var totalOrdered = 0;
                var orders = await dbContext.Orders.ToListAsync();
                foreach (var order in orders)
                {
                    try
                    {
                        var serviceIds = System.Text.Json.JsonSerializer.Deserialize<List<string>>(order.ServiceIds) ?? new List<string>();
                        var serviceQuantities = System.Text.Json.JsonSerializer.Deserialize<List<int>>(order.ServiceQuantities) ?? new List<int>();
                        
                        for (int i = 0; i < serviceIds.Count && i < serviceQuantities.Count; i++)
                        {
                            if (serviceIds[i] == serviceId)
                            {
                                totalOrdered += serviceQuantities[i];
                            }
                        }
                    }
                    catch
                    {
                        // Skip orders with invalid JSON
                        continue;
                    }
                }
                
                var remainingQuantity = totalImported - totalOrdered;
                var isOutOfStock = remainingQuantity <= 0;

                return Ok(new
                {
                    serviceId = serviceId,
                    totalImported = totalImported,
                    totalOrdered = totalOrdered,
                    remainingQuantity = remainingQuantity,
                    isOutOfStock = isOutOfStock
                });
            }
            catch (Exception)
            {
                // Return default values instead of error to prevent blocking
                return Ok(new
                {
                    serviceId = serviceId,
                    totalImported = 0,
                    totalOrdered = 0,
                    remainingQuantity = 0,
                    isOutOfStock = true
                });
            }
        }
    }
}
