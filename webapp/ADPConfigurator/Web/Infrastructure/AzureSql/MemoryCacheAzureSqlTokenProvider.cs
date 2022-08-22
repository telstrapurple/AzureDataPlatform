using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace ADPConfigurator.Web.Infrastructure.AzureSql
{
    public class MemoryCacheAzureSqlTokenProvider : IAzureSqlTokenProvider
    {
        private int _tokenNumber = 0;

        private const string _cacheKey = nameof(MemoryCacheAzureSqlTokenProvider);
        private readonly IAzureSqlTokenProvider _inner;
        private readonly IMemoryCache _cache;
        private readonly ILogger _logger;

        public MemoryCacheAzureSqlTokenProvider(
            IAzureSqlTokenProvider inner,
            IMemoryCache cache,
            ILogger<MemoryCacheAzureSqlTokenProvider> logger)
        {
            _inner = inner;
            _cache = cache;
            _logger = logger;
        }

        public async Task<(string AccessToken, DateTimeOffset ExpiresOn)> GetAccessTokenAsync(CancellationToken cancellationToken = default)
        {
            return await _cache.GetOrCreateAsync(_cacheKey, async cacheEntry =>
            {
                var tokenNumber = Interlocked.Increment(ref _tokenNumber);
                var (token, expiresOn) = await _inner.GetAccessTokenAsync(cancellationToken);

                cacheEntry
                    .SetAbsoluteExpiration(expiresOn)
                    .RegisterPostEvictionCallback(OnEviction, (_logger, tokenNumber));

                _logger.LogInformation(
                    "Requested token number {TokenNumber} that will expire at {ExpiresOn}",
                    tokenNumber,
                    expiresOn);

                return (token, expiresOn);
            });
        }

        public (string AccessToken, DateTimeOffset ExpiresOn) GetAccessToken()
        {
            return _cache.GetOrCreate(_cacheKey, cacheEntry =>
            {
                var tokenNumber = Interlocked.Increment(ref _tokenNumber);
                var (token, expiresOn) = _inner.GetAccessToken();

                cacheEntry
                    .SetAbsoluteExpiration(expiresOn)
                    .RegisterPostEvictionCallback(OnEviction, (_logger, tokenNumber));

                _logger.LogInformation(
                    "Requested token number {TokenNumber} that will expire at {ExpiresOn}",
                    tokenNumber,
                    expiresOn);

                return (token, expiresOn);
            });
        }

        private static void OnEviction(object key, object value, EvictionReason evictionReason, object state)
        {
            var (logger, tokenNumber) = ((ILogger, int))state;

            logger.LogInformation(
                "Token number {TokenNumber} was evicted with reason {EvictionReason} at {EvictedAt}",
                tokenNumber,
                evictionReason,
                DateTimeOffset.Now);
        }
    }
}
