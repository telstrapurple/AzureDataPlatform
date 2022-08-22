using System;
using System.Threading;
using System.Threading.Tasks;
using Azure.Core;
using Azure.Identity;

namespace ADPConfigurator.Common.Infrastructure.AzureSql
{
    public class AzureIdentityAzureSqlTokenProvider : IAzureSqlTokenProvider
    {
        private static readonly string[] _azureSqlScopes = new[]
        {
            "https://database.windows.net//.default"
        };

        private readonly TokenCredential _credential;

        public AzureIdentityAzureSqlTokenProvider()
        {
            _credential = new ChainedTokenCredential(
                new ManagedIdentityCredential(),
                new EnvironmentCredential());
        }

        public async Task<(string AccessToken, DateTimeOffset ExpiresOn)> GetAccessTokenAsync(CancellationToken cancellationToken = default)
        {
            var tokenRequestContext = new TokenRequestContext(_azureSqlScopes);
            var token = await _credential.GetTokenAsync(tokenRequestContext, cancellationToken);

            return (token.Token, token.ExpiresOn);
        }

        public (string AccessToken, DateTimeOffset ExpiresOn) GetAccessToken()
        {
            var tokenRequestContext = new TokenRequestContext(_azureSqlScopes);
            var token = _credential.GetToken(tokenRequestContext, default);

            return (token.Token, token.ExpiresOn);
        }
    }
}
