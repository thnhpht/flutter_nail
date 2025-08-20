using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NailApi.Data;
using NailApi.Models;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CustomersController : ControllerBase
    {
        private readonly AppDbContext _db;
        public CustomersController(AppDbContext db) { _db = db; }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Customer>>> GetAll()
        {
            return await _db.Customers.AsNoTracking().ToListAsync();
        }

        [HttpGet("{phone}")]
        public async Task<ActionResult<Customer>> GetByPhone(string phone)
        {
            var entity = await _db.Customers.FindAsync(phone);
            if (entity == null) return NotFound();
            return entity;
        }

        [HttpPost]
        public async Task<ActionResult<Customer>> Create(Customer input)
        {
            if (string.IsNullOrWhiteSpace(input.PhoneNumber))
                return BadRequest("PhoneNumber is required");

            _db.Customers.Add(input);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetByPhone), new { phone = input.PhoneNumber }, input);
        }

        [HttpPut("{phone}")]
        public async Task<IActionResult> Update(string phone, Customer input)
        {
            if (phone != input.PhoneNumber) return BadRequest("Phone mismatch");
            var exists = await _db.Customers.AnyAsync(c => c.PhoneNumber == phone);
            if (!exists) return NotFound();
            _db.Entry(input).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{phone}")]
        public async Task<IActionResult> Delete(string phone)
        {
            var entity = await _db.Customers.FindAsync(phone);
            if (entity == null) return NotFound();
            _db.Customers.Remove(entity);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}