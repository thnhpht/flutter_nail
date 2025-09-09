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
    public class InformationController : ControllerBase
    {
        private readonly IDatabaseService _databaseService;

        public InformationController(IDatabaseService databaseService)
        {
            _databaseService = databaseService;
        }

        // GET: api/information
        [HttpGet]
        public async Task<ActionResult<Information>> GetInformation()
        {
            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var information = await dbContext.Information.FirstOrDefaultAsync();
                
                if (information == null)
                {
                    return NotFound("Không tìm thấy thông tin salon");
                }

                return Ok(information);
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        // PUT: api/information
        [HttpPut]
        public async Task<IActionResult> UpdateInformation(Information information)
        {
            if (information == null)
            {
                return BadRequest("Information data is required");
            }

            try
            {
                var email = User.FindFirst(ClaimTypes.Email)?.Value;
                var userLogin = User.FindFirst(ClaimTypes.Name)?.Value;
                
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(userLogin))
                    return Unauthorized("Thông tin xác thực không hợp lệ");
                
                var dbContext = await _databaseService.GetDynamicDbContextAsync(email, userLogin, "");
                var existingInfo = await dbContext.Information.FirstOrDefaultAsync();
                
                if (existingInfo == null)
                {
                    // Tạo mới nếu chưa có
                    information.CreatedAt = DateTime.UtcNow;
                    information.UpdatedAt = DateTime.UtcNow;
                    dbContext.Information.Add(information);
                }
                else
                {
                    // Cập nhật thông tin hiện có
                    existingInfo.SalonName = information.SalonName;
                    existingInfo.Address = information.Address;
                    existingInfo.Phone = information.Phone;
                    existingInfo.Email = information.Email;
                    existingInfo.Website = information.Website;
                    existingInfo.Facebook = information.Facebook;
                    existingInfo.Instagram = information.Instagram;
                    existingInfo.Zalo = information.Zalo;
                    existingInfo.Logo = information.Logo;
                    existingInfo.UpdatedAt = DateTime.UtcNow;
                }

                await dbContext.SaveChangesAsync();
                return NoContent();
            }
            catch (DbUpdateConcurrencyException)
            {
                return Conflict("Concurrent update detected. Please try again.");
            }
            catch (Exception ex)
            {
                return BadRequest($"Không thể kết nối database: {ex.Message}");
            }
        }

        // POST: api/information/upload-logo
        [HttpPost("upload-logo")]
        public async Task<ActionResult<string>> UploadLogo(IFormFile file)
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

                return Ok(new { logoUrl = dataUrl });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error processing file: {ex.Message}");
            }
        }
    }
}
