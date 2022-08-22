using System;
using System.Threading;
using System.Threading.Tasks;

namespace ADPConfigurator.Common.Infrastructure.AzureSql
{
    public interface IAzureSqlTokenProvider
    {
        Task<(string AccessToken, DateTimeOffset ExpiresOn)> GetAccessTokenAsync(CancellationToken cancellationToken = default);
        (string AccessToken, DateTimeOffset ExpiresOn) GetAccessToken();
    }
}
