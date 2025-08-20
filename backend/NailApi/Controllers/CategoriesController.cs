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

        [HttpGet("{id:int}")]
        public async Task<ActionResult<Category>> GetById(int id)
        {
            var entity = await _db.Categories.Include(c => c.Items).FirstOrDefaultAsync(c => c.Id == id);
            return entity == null ? NotFound() : entity;
        }

        [HttpPost]
        public async Task<ActionResult<Category>> Create(Category input)
        {
            _db.Categories.Add(input);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetById), new { id = input.Id }, input);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, Category input)
        {
            if (id != input.Id) return BadRequest();
            var exists = await _db.Categories.AnyAsync(c => c.Id == id);
            if (!exists) return NotFound();
            _db.Entry(input).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var entity = await _db.Categories.FindAsync(id);
            if (entity == null) return NotFound();
            _db.Categories.Remove(entity);
            await _db.SaveChangesAsync();
            return NoContent();
        }

        // Items endpoints
        [HttpPost("{categoryId:int}/items")]
        public async Task<ActionResult<CategoryItem>> CreateItem(int categoryId, CategoryItem input)
        {
            if (categoryId != input.CategoryId) return BadRequest();
            _db.CategoryItems.Add(input);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetItemById), new { categoryId, itemId = input.Id }, input);
        }

        [HttpGet("{categoryId:int}/items/{itemId:int}")]
        public async Task<ActionResult<CategoryItem>> GetItemById(int categoryId, int itemId)
        {
            var item = await _db.CategoryItems.FirstOrDefaultAsync(i => i.Id == itemId && i.CategoryId == categoryId);
            return item == null ? NotFound() : item;
        }

        [HttpPut("{categoryId:int}/items/{itemId:int}")]
        public async Task<IActionResult> UpdateItem(int categoryId, int itemId, CategoryItem input)
        {
            if (itemId != input.Id || categoryId != input.CategoryId) return BadRequest();
            var exists = await _db.CategoryItems.AnyAsync(i => i.Id == itemId && i.CategoryId == categoryId);
            if (!exists) return NotFound();
            _db.Entry(input).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{categoryId:int}/items/{itemId:int}")]
        public async Task<IActionResult> DeleteItem(int categoryId, int itemId)
        {
            var entity = await _db.CategoryItems.FirstOrDefaultAsync(i => i.Id == itemId && i.CategoryId == categoryId);
            if (entity == null) return NotFound();
            _db.CategoryItems.Remove(entity);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}