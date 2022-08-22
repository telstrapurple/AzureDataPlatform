using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using Dapper;
using Microsoft.Azure.Services.AppAuthentication;

/// <summary>
/// For raw queries outside our entity framework context
/// </summary>
namespace ADPConfigurator.Domain.Raw
{
    public class Migrations
    {
        private string _connectionString;
        public Migrations(string connectionString)
        {
            _connectionString = connectionString;
        }

        public async Task<IEnumerable<string>> GetMigrations()
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                AzureServiceTokenProvider provider = new AzureServiceTokenProvider();
                var token = await provider.GetAccessTokenAsync("https://database.windows.net/");

                connection.AccessToken = token;
                return connection.Query<Migration>("SELECT * FROM [dbo].SchemaVersions").Select(x => x.ScriptName);
            }
        }
    }
}