using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using NailApi.Data;
using NailApi.Models;
using NailApi.Services;
using System.Text.Json;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BookingController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IPasswordService _passwordService;

        public BookingController(AppDbContext context, IPasswordService passwordService)
        {
            _context = context;
            _passwordService = passwordService;
        }

        // Helper method to get salon owner and connection string
        private async Task<(User? shopOwner, string connectionString)> GetSalonConnectionAsync(string salonName)
        {
            var shopOwner = await _context.Users.FirstOrDefaultAsync(u => u.Email == salonName);
            if (shopOwner == null)
            {
                return (null, string.Empty);
            }

            var connectionString = $"Server=115.78.95.245;Database={salonName};User Id={shopOwner.UserLogin};Password={_passwordService.DecryptPasswordLogin(shopOwner.PasswordLogin)};TrustServerCertificate=True;";
            return (shopOwner, connectionString);
        }

        [HttpGet("categories")]
        public async Task<ActionResult<IEnumerable<Category>>> GetCategories([FromQuery] string salonName)
        {
            try
            {
                Console.WriteLine($"Getting categories for salon: {salonName}");

                var (shopOwner, connectionString) = await GetSalonConnectionAsync(salonName);
                if (shopOwner == null)
                {
                    return BadRequest("Salon không tồn tại trong hệ thống");
                }

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    var categories = new List<Category>();
                    var command = new SqlCommand("SELECT Id, Name, Image FROM Categories ORDER BY Name", connection);

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            categories.Add(new Category
                            {
                                Id = reader["Id"].ToString() ?? "",
                                Name = reader["Name"].ToString() ?? "",
                                Image = reader["Image"].ToString()
                            });
                        }
                    }

                    return Ok(categories);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Get categories error: {ex.Message}");
                return BadRequest($"Không thể lấy danh sách categories: {ex.Message}");
            }
        }

        [HttpGet("services")]
        public async Task<ActionResult<IEnumerable<Service>>> GetServices([FromQuery] string salonName)
        {
            try
            {
                Console.WriteLine($"Getting services for salon: {salonName}");

                var (shopOwner, connectionString) = await GetSalonConnectionAsync(salonName);
                if (shopOwner == null)
                {
                    return BadRequest("Salon không tồn tại trong hệ thống");
                }

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    var services = new List<Service>();
                    var command = new SqlCommand("SELECT Id, Name, Price, CategoryId, Image, Code, Unit FROM Services ORDER BY Price", connection);

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            services.Add(new Service
                            {
                                Id = reader["Id"].ToString() ?? "",
                                Name = reader["Name"].ToString() ?? "",
                                Price = Convert.ToDecimal(reader["Price"]),
                                CategoryId = reader["CategoryId"].ToString() ?? "",
                                Image = reader["Image"].ToString(),
                                Code = Convert.ToInt32(reader["Code"]),
                                Unit = reader["Unit"].ToString()
                            });
                        }
                    }

                    return Ok(services);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Get services error: {ex.Message}");
                return BadRequest($"Không thể lấy danh sách services: {ex.Message}");
            }
        }

        [HttpGet("information")]
        public async Task<ActionResult<Information>> GetInformation([FromQuery] string salonName)
        {
            try
            {
                Console.WriteLine($"Getting information for salon: {salonName}");

                var (shopOwner, connectionString) = await GetSalonConnectionAsync(salonName);
                if (shopOwner == null)
                {
                    return BadRequest("Salon không tồn tại trong hệ thống");
                }

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    var command = new SqlCommand("SELECT TOP 1 Id, SalonName, Address, Phone, Email, Website, Facebook, Instagram, Zalo, Logo, QRCode, Contact, ThankYouMessage, CreatedAt, UpdatedAt FROM Information", connection);

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            var information = new Information
                            {
                                Id = Convert.ToInt32(reader["Id"]),
                                SalonName = reader["SalonName"].ToString() ?? "",
                                Address = reader["Address"].ToString() ?? "",
                                Phone = reader["Phone"].ToString() ?? "",
                                Email = reader["Email"].ToString() ?? "",
                                Website = reader["Website"].ToString() ?? "",
                                Facebook = reader["Facebook"].ToString() ?? "",
                                Instagram = reader["Instagram"].ToString() ?? "",
                                Zalo = reader["Zalo"].ToString() ?? "",
                                Logo = reader["Logo"].ToString() ?? "",
                                QRCode = reader["QRCode"].ToString() ?? "",
                                Contact = reader["Contact"].ToString() ?? "",
                                ThankYouMessage = reader["ThankYouMessage"].ToString() ?? "",
                                CreatedAt = Convert.ToDateTime(reader["CreatedAt"]),
                                UpdatedAt = Convert.ToDateTime(reader["UpdatedAt"])
                            };

                            return Ok(information);
                        }
                        else
                        {
                            return NotFound("Không tìm thấy thông tin salon");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Get information error: {ex.Message}");
                return BadRequest($"Không thể lấy thông tin salon: {ex.Message}");
            }
        }

        [HttpGet("customers")]
        public async Task<ActionResult<IEnumerable<Customer>>> GetCustomers([FromQuery] string salonName)
        {
            try
            {
                Console.WriteLine($"Getting customers for salon: {salonName}");

                var (shopOwner, connectionString) = await GetSalonConnectionAsync(salonName);
                if (shopOwner == null)
                {
                    return BadRequest("Salon không tồn tại trong hệ thống");
                }

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    var command = new SqlCommand("SELECT Phone, Name, Address FROM Customers ORDER BY Name", connection);
                    var customers = new List<Customer>();

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            customers.Add(new Customer
                            {
                                Phone = reader["Phone"].ToString() ?? "",
                                Name = reader["Name"].ToString() ?? "",
                                Address = reader["Address"].ToString()
                            });
                        }
                    }

                    return Ok(customers);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Get customers error: {ex.Message}");
                return BadRequest($"Không thể lấy danh sách customers: {ex.Message}");
            }
        }

        [HttpGet("customers/{phone}")]
        public async Task<ActionResult<Customer>> GetCustomer(string phone, [FromQuery] string salonName)
        {
            try
            {
                Console.WriteLine($"Getting customer {phone} for salon: {salonName}");

                var (shopOwner, connectionString) = await GetSalonConnectionAsync(salonName);
                if (shopOwner == null)
                {
                    return BadRequest("Salon không tồn tại trong hệ thống");
                }

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    var command = new SqlCommand("SELECT Phone, Name, Address FROM Customers WHERE Phone = @Phone", connection);
                    command.Parameters.AddWithValue("@Phone", phone);

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            var customer = new Customer
                            {
                                Phone = reader["Phone"].ToString() ?? "",
                                Name = reader["Name"].ToString() ?? "",
                                Address = reader["Address"].ToString()
                            };
                            return Ok(customer);
                        }
                        else
                        {
                            return NotFound("Không tìm thấy khách hàng");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Get customer error: {ex.Message}");
                return BadRequest($"Không thể lấy thông tin khách hàng: {ex.Message}");
            }
        }

        [HttpGet("servicedetails/inventory")]
        public async Task<ActionResult<IEnumerable<object>>> GetServiceInventory([FromQuery] string salonName)
        {
            try
            {
                Console.WriteLine($"Getting service inventory for salon: {salonName}");

                var (shopOwner, connectionString) = await GetSalonConnectionAsync(salonName);
                if (shopOwner == null)
                {
                    return BadRequest("Salon không tồn tại trong hệ thống");
                }

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Get all services
                    var services = new List<Service>();
                    var servicesCommand = new SqlCommand("SELECT Id, Name, Price, CategoryId, Image, Code, Unit FROM Services", connection);

                    using (var reader = await servicesCommand.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            services.Add(new Service
                            {
                                Id = reader["Id"].ToString() ?? "",
                                Name = reader["Name"].ToString() ?? "",
                                Price = Convert.ToDecimal(reader["Price"]),
                                CategoryId = reader["CategoryId"].ToString() ?? "",
                                Image = reader["Image"].ToString(),
                                Code = Convert.ToInt32(reader["Code"]),
                                Unit = reader["Unit"].ToString()
                            });
                        }
                    }

                    var inventory = new List<object>();

                    foreach (var service in services)
                    {
                        try
                        {
                            // Calculate total imported quantity
                            var totalImportedCommand = new SqlCommand(
                                "SELECT ISNULL(SUM(Quantity), 0) FROM ServiceDetails WHERE ServiceId = @ServiceId", 
                                connection);
                            totalImportedCommand.Parameters.AddWithValue("@ServiceId", service.Id);
                            var totalImported = Convert.ToInt32(await totalImportedCommand.ExecuteScalarAsync());

                            // Calculate total ordered quantity
                            // This is a simplified approach - we'll get all orders and calculate in C#
                            var totalOrdered = 0;
                            var ordersCommand = new SqlCommand("SELECT ServiceIds, ServiceQuantities FROM Orders WHERE ServiceIds LIKE '%' + @ServiceId + '%'", connection);
                            ordersCommand.Parameters.AddWithValue("@ServiceId", service.Id);
                            
                            using (var ordersReader = await ordersCommand.ExecuteReaderAsync())
                            {
                                while (await ordersReader.ReadAsync())
                                {
                                    try
                                    {
                                        var serviceIdsJson = ordersReader["ServiceIds"].ToString() ?? "[]";
                                        var serviceQuantitiesJson = ordersReader["ServiceQuantities"].ToString() ?? "[]";
                                        
                                        var serviceIds = JsonSerializer.Deserialize<List<string>>(serviceIdsJson) ?? new List<string>();
                                        var serviceQuantities = JsonSerializer.Deserialize<List<int>>(serviceQuantitiesJson) ?? new List<int>();
                                        
                                        // Find the index of the service in the serviceIds array
                                        var serviceIndex = serviceIds.IndexOf(service.Id);
                                        if (serviceIndex >= 0 && serviceIndex < serviceQuantities.Count)
                                        {
                                            totalOrdered += serviceQuantities[serviceIndex];
                                        }
                                    }
                                    catch (Exception jsonEx)
                                    {
                                        Console.WriteLine($"Error parsing order JSON for service {service.Id}: {jsonEx.Message}");
                                    }
                                }
                            }

                            var remainingQuantity = totalImported - totalOrdered;
                            var isOutOfStock = remainingQuantity <= 0;

                            inventory.Add(new
                            {
                                serviceId = service.Id,
                                totalImported = totalImported,
                                totalOrdered = totalOrdered,
                                remainingQuantity = remainingQuantity,
                                isOutOfStock = isOutOfStock
                            });
                        }
                        catch (Exception serviceEx)
                        {
                            Console.WriteLine($"Error calculating inventory for service {service.Id}: {serviceEx.Message}");
                            // If individual service calculation fails, add default values
                            inventory.Add(new
                            {
                                serviceId = service.Id,
                                totalImported = 0,
                                totalOrdered = 0,
                                remainingQuantity = 0,
                                isOutOfStock = true
                            });
                        }
                    }

                    return Ok(inventory);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Get service inventory error: {ex.Message}");
                // Return empty inventory list instead of error to prevent blocking services
                return Ok(new List<object>());
            }
        }

        [HttpPost("orders")]
        public async Task<ActionResult<Order>> CreateOrder([FromBody] BookingOrderRequest request)
        {
            try
            {
                Console.WriteLine($"Creating booking order for salon: {request.SalonName}");

                var (shopOwner, connectionString) = await GetSalonConnectionAsync(request.SalonName);
                if (shopOwner == null)
                {
                    return BadRequest("Salon không tồn tại trong hệ thống");
                }

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Create the order
                    var orderId = Guid.NewGuid().ToString();
                    var createdAt = DateTime.Now;

                    var insertCommand = new SqlCommand(@"
                        INSERT INTO Orders (Id, CustomerPhone, CustomerName, CustomerAddress, EmployeeIds, EmployeeNames, 
                                          ServiceIds, ServiceNames, ServiceQuantities, TotalPrice, DiscountPercent, Tip, 
                                          TaxPercent, ShippingFee, CreatedAt, IsPaid, IsBooking, DeliveryMethod)
                        VALUES (@Id, @CustomerPhone, @CustomerName, @CustomerAddress, @EmployeeIds, @EmployeeNames,
                                @ServiceIds, @ServiceNames, @ServiceQuantities, @TotalPrice, @DiscountPercent, @Tip,
                                @TaxPercent, @ShippingFee, @CreatedAt, @IsPaid, @IsBooking, @DeliveryMethod)", connection);

                    insertCommand.Parameters.AddWithValue("@Id", orderId);
                    insertCommand.Parameters.AddWithValue("@CustomerPhone", request.CustomerPhone);
                    insertCommand.Parameters.AddWithValue("@CustomerName", request.CustomerName);
                    insertCommand.Parameters.AddWithValue("@CustomerAddress", request.CustomerAddress ?? "");
                    insertCommand.Parameters.AddWithValue("@EmployeeIds", "[]"); // No employees for booking
                    insertCommand.Parameters.AddWithValue("@EmployeeNames", "[]"); // No employees for booking
                    insertCommand.Parameters.AddWithValue("@ServiceIds", JsonSerializer.Serialize(request.ServiceIds));
                    insertCommand.Parameters.AddWithValue("@ServiceNames", JsonSerializer.Serialize(request.ServiceNames));
                    insertCommand.Parameters.AddWithValue("@ServiceQuantities", JsonSerializer.Serialize(request.ServiceQuantities));
                    insertCommand.Parameters.AddWithValue("@TotalPrice", (decimal)request.TotalPrice);
                    insertCommand.Parameters.AddWithValue("@DiscountPercent", 0.0M);
                    insertCommand.Parameters.AddWithValue("@Tip", 0.0M);
                    insertCommand.Parameters.AddWithValue("@TaxPercent", 0.0M);
                    insertCommand.Parameters.AddWithValue("@ShippingFee", 0.0M);
                    insertCommand.Parameters.AddWithValue("@CreatedAt", createdAt);
                    insertCommand.Parameters.AddWithValue("@IsPaid", false);
                    insertCommand.Parameters.AddWithValue("@IsBooking", true); // This is a booking order
                    insertCommand.Parameters.AddWithValue("@DeliveryMethod", request.DeliveryMethod);

                    await insertCommand.ExecuteNonQueryAsync();

                    // Create notification for booking order
                    var notificationId = Guid.NewGuid().ToString();
                    var notificationData = JsonSerializer.Serialize(new
                    {
                        orderId = orderId,
                        customerName = request.CustomerName,
                        customerPhone = request.CustomerPhone,
                        totalPrice = request.TotalPrice
                    });

                    var notificationCommand = new SqlCommand(@"
                        INSERT INTO [Notifications] (Id, Title, Message, Type, CreatedAt, IsRead, Data)
                        VALUES (@id, @title, @message, @type, @createdAt, @isRead, @data)", connection);

                    notificationCommand.Parameters.AddWithValue("@id", notificationId);
                    notificationCommand.Parameters.AddWithValue("@title", "Đơn đặt hàng mới");
                    notificationCommand.Parameters.AddWithValue("@message", 
                        $"Khách hàng {request.CustomerName} ({request.CustomerPhone}) đã tạo đơn đặt hàng với tổng tiền {request.TotalPrice:N0} VNĐ");
                    notificationCommand.Parameters.AddWithValue("@type", "booking_created");
                    notificationCommand.Parameters.AddWithValue("@createdAt", DateTime.Now);
                    notificationCommand.Parameters.AddWithValue("@isRead", false);
                    notificationCommand.Parameters.AddWithValue("@data", notificationData);

                    await notificationCommand.ExecuteNonQueryAsync();
                    Console.WriteLine($"Booking notification created with ID: {notificationId}");

                    // Return the created order
                    var order = new Order
                    {
                        Id = orderId,
                        CustomerPhone = request.CustomerPhone,
                        CustomerName = request.CustomerName,
                        CustomerAddress = request.CustomerAddress,
                        EmployeeIds = "[]",
                        EmployeeNames = "[]",
                        ServiceIds = JsonSerializer.Serialize(request.ServiceIds),
                        ServiceNames = JsonSerializer.Serialize(request.ServiceNames),
                        ServiceQuantities = JsonSerializer.Serialize(request.ServiceQuantities),
                        TotalPrice = (decimal)request.TotalPrice,
                        DiscountPercent = 0.0M,
                        Tip = 0.0M,
                        TaxPercent = 0.0M,
                        ShippingFee = 0.0M,
                        CreatedAt = createdAt,
                        IsPaid = false,
                        IsBooking = true, // This is a booking order
                        DeliveryMethod = request.DeliveryMethod
                    };

                    return CreatedAtAction(nameof(CreateOrder), new { id = orderId }, order);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Create booking order error: {ex.Message}");
                return BadRequest($"Không thể tạo booking order: {ex.Message}");
            }
        }

        // Request model for booking orders
        public class BookingOrderRequest
        {
            public string SalonName { get; set; } = string.Empty;
            public string CustomerPhone { get; set; } = string.Empty;
            public string CustomerName { get; set; } = string.Empty;
            public string? CustomerAddress { get; set; }
            public List<string> ServiceIds { get; set; } = new List<string>();
            public List<string> ServiceNames { get; set; } = new List<string>();
            public List<int> ServiceQuantities { get; set; } = new List<int>();
            public double TotalPrice { get; set; }
            public string DeliveryMethod { get; set; } = "pickup"; // "pickup" or "delivery"
        }
    }
}
