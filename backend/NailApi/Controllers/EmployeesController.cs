using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NailApi.Data;
using NailApi.Models;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class EmployeesController : ControllerBase
    {
        private readonly AppDbContext _db;
        public EmployeesController(AppDbContext db) { _db = db; }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Employee>>> GetAll() =>
            await _db.Employees.AsNoTracking().ToListAsync();

        [HttpGet("{id:int}")]
        public async Task<ActionResult<Employee>> GetById(int id)
        {
            var entity = await _db.Employees.FindAsync(id);
            return entity == null ? NotFound() : entity;
        }

        [HttpPost]
        public async Task<ActionResult<Employee>> Create(Employee input)
        {
            _db.Employees.Add(input);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetById), new { id = input.Id }, input);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, Employee input)
        {
            if (id != input.Id) return BadRequest();
            var exists = await _db.Employees.AnyAsync(e => e.Id == id);
            if (!exists) return NotFound();
            _db.Entry(input).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var entity = await _db.Employees.FindAsync(id);
            if (entity == null) return NotFound();
            _db.Employees.Remove(entity);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}