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
    public class ServicesController : ControllerBase
    {
        private readonly IDatabaseService _databaseService;

        public ServicesController(IDatabaseService databaseService)
        {
            _databaseService = databaseService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Service>>> GetAll()
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                return await dbContext.Services.AsNoTracking().ToListAsync();
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Service>> GetById(string id)
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var entity = await dbContext.Services.FindAsync(id);
                if (entity == null) return NotFound();
                return entity;
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<Service>> Create(Service input)
        {
            if (string.IsNullOrWhiteSpace(input.Name))
                return BadRequest("Name is required");

            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                dbContext.Services.Add(input);
                await dbContext.SaveChangesAsync();
                return CreatedAtAction(nameof(GetById), new { id = input.Id }, input);
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, Service input)
        {
            if (id != input.Id) return BadRequest("Id mismatch");
            
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var exists = await dbContext.Services.FindAsync(id);
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
                var entity = await dbContext.Services.FindAsync(id);
                if (entity == null) return NotFound();
                dbContext.Services.Remove(entity);
                await dbContext.SaveChangesAsync();
                return NoContent();
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }
    }
}