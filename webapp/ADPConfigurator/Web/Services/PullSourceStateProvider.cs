using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Raw;
using Microsoft.Extensions.Configuration;

namespace ADPConfigurator.Web.Services
{
    public class PullSourceStateProvider
    {
        private IConfiguration _configuration;

        private ConfiguratorApiClient _apiClient;

        private IEnumerable<string> _migrationsRunHere;

        private IEnumerable<string> _migrationsRunAtPullSource;

        public async Task<IEnumerable<string>> MigrationsRunAtPullSource()
        {
            if (_migrationsRunAtPullSource == null)
            {
                _migrationsRunAtPullSource = (await _apiClient.GetMigrations());
            }
            return _migrationsRunAtPullSource;
        }

        public async Task<IEnumerable<string>> MigrationsRunHere()
        {
            if (_migrationsRunHere == null)
            {
                var connectionString = _configuration["ApplicationConfig:ConnectionString"];
                var migrationFetcher = new Migrations(connectionString);
                _migrationsRunHere = await migrationFetcher.GetMigrations();
            }

            return _migrationsRunHere;
        }

        public async Task<bool> InSync()
        {
            return Enumerable.SequenceEqual(
                (await MigrationsRunAtPullSource()).OrderBy(x => x),
                (await MigrationsRunHere()).OrderBy(x => x)
            );
        }

        public bool HasPullSource()
        {
            return !string.IsNullOrEmpty(_configuration["PullSource:BaseUrl"]);
        }

        public PullSourceStateProvider(IConfiguration configuration, ConfiguratorApiClient apiClient)
        {
            _configuration = configuration;
            _apiClient = apiClient;
        }
    }
}