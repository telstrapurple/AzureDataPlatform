using ADPConfigurator.Domain.Models;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using ADPConfigurator.Domain.Repositories;

namespace ADPConfigurator.Api.Controllers
{
    [ApiController]
    [Route("[controller]")]

    public class SystemController : Controller
    {
        private ADS_ConfigContext _context;
        private SystemRepository _systemRepository;

        public SystemController(ADS_ConfigContext dbContext, SystemRepository systemRepository)
        {
            _context = dbContext;
            _systemRepository = systemRepository;
        }

        [HttpGet]
        public async Task<IActionResult> Get(string systemName)
        {
            // The client will use the names of system property types to correlate
            // because IDs are generated, and different across environments
            // So we have to send them everything we need to correlate relattionships
            var pulledSystem = await _systemRepository.GetFullyTraversedSystem(systemName);

            if (pulledSystem == null)
            {
                return NotFound();
            }

            // Decirculate for serialisation
            var decirculatedJson = JsonConvert.SerializeObject(pulledSystem, Formatting.None, new JsonSerializerSettings()
            {
                ReferenceLoopHandling = ReferenceLoopHandling.Ignore
            });

            return Ok(JToken.Parse(decirculatedJson));
        }
    }
}
