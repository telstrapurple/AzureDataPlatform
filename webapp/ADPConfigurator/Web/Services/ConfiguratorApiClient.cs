using Microsoft.Identity.Web;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace ADPConfigurator.Web.Services
{
    public class ConfiguratorApiClient
    {
        public static string ApiName = "PullSource";
        private IDownstreamWebApi _downstreamWebApi;

        public ConfiguratorApiClient(IDownstreamWebApi downstreamWebApi)
        {
            _downstreamWebApi = downstreamWebApi;
        }

        public Task<IEnumerable<string>> GetMigrations()
        {
            return _downstreamWebApi.GetForUserAsync<IEnumerable<string>>(ApiName, "migrationState");
        }

        public Task<Domain.Models.System> GetSystem(string systemName)
        {
            return _downstreamWebApi
                .GetForUserAsync<Domain.Models.System>(ApiName, $"system?systemName={systemName}");
        }
    }

    public class SystemQueryByName
    {
        public string systemName { get; set; }
    }
}