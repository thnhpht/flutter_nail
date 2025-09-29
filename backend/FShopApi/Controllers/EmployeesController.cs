using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FShopApi.Data;
using FShopApi.Models;
using FShopApi.Services;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace FShopApi.Controllers
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
                exists.Image = input.Image;

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

        // POST: api/employees/upload-image
        [HttpPost("upload-image")]
        public async Task<ActionResult<string>> UploadImage(IFormFile file)
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
