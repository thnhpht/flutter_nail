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
    public class EmployeesController : ControllerBase
    {
        private readonly IDatabaseService _databaseService;
        private readonly IPasswordService _passwordService;

        public EmployeesController(IDatabaseService databaseService, IPasswordService passwordService)
        {
            _databaseService = databaseService;
            _passwordService = passwordService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Employee>>> GetAll()
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var employees = await dbContext.Employees.AsNoTracking().ToListAsync();

                // Don't return passwords
                foreach (var employee in employees)
                {
                    employee.Password = "";
                }

                return employees;
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Employee>> GetById(string id)
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var entity = await dbContext.Employees.FindAsync(id);
                if (entity == null) return NotFound();

                // Don't return password
                entity.Password = "";
                return entity;
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<Employee>> Create(Employee input)
        {

            if (string.IsNullOrWhiteSpace(input.Name))
                return BadRequest("Name is required");

            // Password luôn required khi tạo mới
            if (string.IsNullOrWhiteSpace(input.Password))
                return BadRequest("Password là bắt buộc khi tạo mới");

            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");

                // Hash the password before saving
                input.Password = _passwordService.HashPassword(input.Password);

                dbContext.Employees.Add(input);
                await dbContext.SaveChangesAsync();

                // Don't return the hashed password
                input.Password = "";
                return CreatedAtAction(nameof(GetById), new { id = input.Id }, input);
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, Employee input)
        {
            if (id != input.Id) return BadRequest("Id mismatch");

            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");

                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var exists = await dbContext.Employees.FindAsync(id);
                if (exists == null) return NotFound();

                // Check for duplicate phone number
                if (!string.IsNullOrEmpty(input.Phone) && input.Phone != exists.Phone)
                {
                    var phoneExists = await dbContext.Employees
                        .AnyAsync(e => e.Phone == input.Phone && e.Id != id);
                    if (phoneExists)
                    {
                        return BadRequest("Số điện thoại đã được sử dụng bởi nhân viên khác");
                    }
                }

                // Cập nhật các trường thông tin cơ bản
                exists.Name = input.Name.Trim();
                exists.Phone = string.IsNullOrWhiteSpace(input.Phone) ? null : input.Phone.Trim();

                // Chỉ cập nhật mật khẩu nếu được cung cấp
                if (!string.IsNullOrWhiteSpace(input.Password))
                {
                    exists.Password = _passwordService.HashPassword(input.Password);
                }

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
                var entity = await dbContext.Employees.FindAsync(id);
                if (entity == null) return NotFound();
                dbContext.Employees.Remove(entity);
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
