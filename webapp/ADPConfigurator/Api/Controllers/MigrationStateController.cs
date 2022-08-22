using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Raw;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Identity.Web.Resource;

namespace ADPConfigurator.Api.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class MigrationStateController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public MigrationStateController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        /// <returns>A list of all migrations run against the environment</returns>
        [HttpGet]
        public async Task<IEnumerable<string>> Get()
        {
            var connectionString = _configuration["ApplicationConfig:ConnectionString"];
            var fetcher = new Migrations(connectionString);
            return await fetcher.GetMigrations();
        }
    }
}
