using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NailApi.Data;
using NailApi.Models;
using System.Text.Json;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrdersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public OrdersController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/orders
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrders()
        {
            return await _context.Orders.ToListAsync();
        }

        // GET: api/orders/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<Order>> GetOrder(Guid id)
        {
            var order = await _context.Orders.FindAsync(id);

            if (order == null)
            {
                return NotFound();
            }

            return order;
        }

        // POST: api/orders
        [HttpPost]
        public async Task<ActionResult<Order>> CreateOrder(Order order)
        {
            // Generate new ID if empty
            if (order.Id == Guid.Empty)
            {
                order.Id = Guid.NewGuid();
            }

            // Convert service lists to JSON strings for storage
            if (order.ServiceIds != null && order.ServiceIds != "[]")
            {
                // If ServiceIds is already a JSON string, keep it
                // Otherwise, assume it's a list and convert to JSON
                try
                {
                    JsonSerializer.Deserialize<string[]>(order.ServiceIds);
                }
                catch
                {
                    // If it's not valid JSON, assume it's a comma-separated string
                    var serviceIds = order.ServiceIds.Split(',').Select(s => s.Trim()).ToArray();
                    order.ServiceIds = JsonSerializer.Serialize(serviceIds);
                }
            }

            if (order.ServiceNames != null && order.ServiceNames != "[]")
            {
                try
                {
                    JsonSerializer.Deserialize<string[]>(order.ServiceNames);
                }
                catch
                {
                    var serviceNames = order.ServiceNames.Split(',').Select(s => s.Trim()).ToArray();
                    order.ServiceNames = JsonSerializer.Serialize(serviceNames);
                }
            }

            order.CreatedAt = DateTime.Now;
            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, order);
        }

        // PUT: api/orders/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateOrder(Guid id, Order order)
        {
            if (id != order.Id)
            {
                return BadRequest();
            }

            _context.Entry(order).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!OrderExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // DELETE: api/orders/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteOrder(Guid id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
            {
                return NotFound();
            }

            _context.Orders.Remove(order);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool OrderExists(Guid id)
        {
            return _context.Orders.Any(e => e.Id == id);
        }
    }
}
