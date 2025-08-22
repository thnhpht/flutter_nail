using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NailApi.Data;
using NailApi.Models;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CategoriesController : ControllerBase
    {
        private readonly AppDbContext _db;
        public CategoriesController(AppDbContext db) { _db = db; }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Category>>> GetAll()
        {
            return await _db.Categories
                .Include(c => c.Items)
                .AsNoTracking()
                .ToListAsync();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Category>> GetById(string id)
        {
            var entity = await _db.Categories.Include(c => c.Items).FirstOrDefaultAsync(c => c.Id == id);
            return entity == null ? NotFound() : entity;
        }

        [HttpPost]
        public async Task<ActionResult<Category>> Create(Category input)
        {
            if (string.IsNullOrWhiteSpace(input.Id))
                input.Id = Guid.NewGuid().ToString();
            _db.Categories.Add(input);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetById), new { id = input.Id }, input);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, Category input)
        {
            if (!id.Equals(input.Id)) return BadRequest();
            var exists = await _db.Categories.AnyAsync(c => c.Id == id);
            if (!exists) return NotFound();
            _db.Entry(input).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            var entity = await _db.Categories.FindAsync(id);
            if (entity == null) return NotFound();
            _db.Categories.Remove(entity);
            await _db.SaveChangesAsync();
            return NoContent();
        }

        // Items endpoints
        [HttpPost("{categoryId}/items")]
        public async Task<ActionResult<Service>> CreateItem(string categoryId, Service input)
        {
            if (!categoryId.Equals(input.CategoryId)) return BadRequest();
            if (string.IsNullOrWhiteSpace(input.Id))
                input.Id = Guid.NewGuid().ToString();
            _db.Services.Add(input);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetItemById), new { categoryId, itemId = input.Id }, input);
        }

        [HttpGet("{categoryId}/items/{itemId}")]
        public async Task<ActionResult<Service>> GetItemById(string categoryId, string itemId)
        {
            var entity = await _db.Services.FirstOrDefaultAsync(s => s.CategoryId.Equals(categoryId) && s.Id == itemId);
            return entity == null ? NotFound() : entity;
        }

        [HttpPut("{categoryId}/items/{itemId}")]
        public async Task<IActionResult> UpdateItem(string categoryId, string itemId, Service input)
        {
            if (!itemId.Equals(input.Id) || !categoryId.Equals(input.CategoryId)) return BadRequest();
            var exists = await _db.Services.AnyAsync(s => s.Id == itemId && s.CategoryId.Equals(categoryId));
            if (!exists) return NotFound();
            _db.Entry(input).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{categoryId}/items/{itemId}")]
        public async Task<IActionResult> DeleteItem(string categoryId, string itemId)
        {
            var entity = await _db.Services.FirstOrDefaultAsync(s => s.CategoryId.Equals(categoryId) && s.Id == itemId);
            if (entity == null) return NotFound();
            _db.Services.Remove(entity);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}