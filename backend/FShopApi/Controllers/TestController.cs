using Microsoft.AspNetCore.Mvc;

namespace NailApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        [HttpGet]
        public ActionResult<string> Get()
        {
            return Ok("TestController đang hoạt động!");
        }

        [HttpGet("hello")]
        public ActionResult<string> Hello()
        {
            return Ok("Hello World!");
        }
    }
}
