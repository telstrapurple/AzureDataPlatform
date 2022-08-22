using System.Data.Common;
using System.Data.SqlClient;
using System.Threading;
using System.Threading.Tasks;
using ADPConfigurator.Common.Infrastructure.AzureSql;
using Microsoft.EntityFrameworkCore.Diagnostics;
using System;

namespace ADPConfigurator.Api.Infrastructure.AzureSql
{
    public class AzureAdAuthenticationDbConnectionInterceptor : DbConnectionInterceptor
    {
        private readonly IAzureSqlTokenProvider _tokenProvider;

        public AzureAdAuthenticationDbConnectionInterceptor(IAzureSqlTokenProvider tokenProvider)
        {
            _tokenProvider = tokenProvider;
        }

        public override InterceptionResult ConnectionOpening(
            DbConnection connection,
            ConnectionEventData eventData,
            InterceptionResult result)
        {
            var sqlConnection = (Microsoft.Data.SqlClient.SqlConnection)connection;
            if (DoesConnectionNeedAccessToken(sqlConnection))
            {
                var (token, _) = _tokenProvider.GetAccessToken();
                sqlConnection.AccessToken = token;
            }

            return base.ConnectionOpening(connection, eventData, result);
        }

        public override async Task<InterceptionResult> ConnectionOpeningAsync(
            DbConnection connection,
            ConnectionEventData eventData,
            InterceptionResult result,
            CancellationToken cancellationToken = default)
        {
            var sqlConnection = (Microsoft.Data.SqlClient.SqlConnection)connection;
            if (DoesConnectionNeedAccessToken(sqlConnection))
            {
                var (token, _) = await _tokenProvider.GetAccessTokenAsync(cancellationToken);
                sqlConnection.AccessToken = token;
            }

            return await base.ConnectionOpeningAsync(connection, eventData, result, cancellationToken);
        }

        public override Task ConnectionOpenedAsync(DbConnection connection, ConnectionEndEventData eventData, CancellationToken cancellationToken = default)
        {
            OrchestrateSession(connection);
            return base.ConnectionOpenedAsync(connection, eventData, cancellationToken);
        }

        public override void ConnectionOpened(DbConnection connection, ConnectionEndEventData eventData)
        {
            OrchestrateSession(connection);
            base.ConnectionOpened(connection, eventData);
        }

        /// <summary>
        /// The logged in service principal should be marked as a global admin for full read access
        /// </summary>
        private void OrchestrateSession(DbConnection connection)
        {
            DbCommand setIsGlobalAdminCommand = connection.CreateCommand();
            setIsGlobalAdminCommand.CommandText = @"
EXEC sys.sp_set_session_context @key = N'IsGlobalAdmin', @value = true";
            setIsGlobalAdminCommand.ExecuteNonQuery();
        }

        private static bool DoesConnectionNeedAccessToken(Microsoft.Data.SqlClient.SqlConnection connection)
        {
            //
            // Only try to get a token from AAD if
            //  - We connect to an Azure SQL instance; and
            //  - The connection doesn't specify a username.
            //
            var connectionStringBuilder = new SqlConnectionStringBuilder(connection.ConnectionString);

            return connectionStringBuilder.DataSource.Contains("database.windows.net", StringComparison.OrdinalIgnoreCase) && string.IsNullOrEmpty(connectionStringBuilder.UserID);
        }
    }
}
