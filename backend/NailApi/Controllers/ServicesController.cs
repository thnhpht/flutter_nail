using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NailApi.Data;
using NailApi.Models;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/services")]
    public class ServicesController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ServicesController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Service>>> GetAll()
        {
            return await _db.Services.AsNoTracking().ToListAsync();
        }

        [HttpPost]
        public async Task<ActionResult<Service>> Create(Service input)
        {
            if (string.IsNullOrWhiteSpace(input.Id))
                input.Id = Guid.NewGuid().ToString();
            _db.Services.Add(input);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetById), new { id = input.Id }, input);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Service>> GetById(string id)
        {
            var entity = await _db.Services.FindAsync(id);
            return entity == null ? NotFound() : entity;
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, Service input)
        {
            if (id != input.Id) return BadRequest();
            _db.Entry(input).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            var entity = await _db.Services.FindAsync(id);
            if (entity == null) return NotFound();
            _db.Services.Remove(entity);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}