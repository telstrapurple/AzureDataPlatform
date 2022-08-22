using System;
using System.Data.Common;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using ADPConfigurator.Web.Services;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Identity.Web;

namespace ADPConfigurator.Web.Infrastructure.AzureSql
{
    public class AzureAdAuthenticationDbConnectionInterceptor : DbConnectionInterceptor
    {
        private readonly IAzureSqlTokenProvider _tokenProvider;
        private readonly PrincipalProvider _principalProvider;

        public AzureAdAuthenticationDbConnectionInterceptor(IAzureSqlTokenProvider tokenProvider, PrincipalProvider principalProvider)
        {
            _tokenProvider = tokenProvider;
            _principalProvider = principalProvider;
        }

        public override InterceptionResult ConnectionOpening(
            DbConnection connection,
            ConnectionEventData eventData,
            InterceptionResult result)
        {
            var sqlConnection = (SqlConnection)connection;
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
            var sqlConnection = (SqlConnection)connection;
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
        /// Set session variables indicating what groups the user belongs to
        /// and whether they are a global admin
        /// </summary>
        private void OrchestrateSession(DbConnection connection)
        {
            var serialisedGroups = JsonSerializer.Serialize(_principalProvider.Groups);

            DbCommand setGroupsCommand = connection.CreateCommand();
            setGroupsCommand.CommandText = "EXEC sp_set_session_context @key=N'UserGroups', @value=@UserGroups";
            DbParameter groupsParam = setGroupsCommand.CreateParameter();
            groupsParam.ParameterName = "@UserGroups";
            groupsParam.Value = serialisedGroups;
            groupsParam.DbType = System.Data.DbType.AnsiString;
            setGroupsCommand.Parameters.Add(groupsParam);
            setGroupsCommand.ExecuteNonQuery();

            DbCommand setIsGlobalAdminCommand = connection.CreateCommand();
            setIsGlobalAdminCommand.CommandText = @"
DECLARE @IsGlobalAdmin sql_variant
SELECT @IsGlobalAdmin = (SELECT CAST(AdminIndicator as sql_variant) FROM [DI].[User] WHERE UserId = @UserId)
EXEC sys.sp_set_session_context @key = N'IsGlobalAdmin', @value = @IsGlobalAdmin";
            DbParameter userIdParam = setIsGlobalAdminCommand.CreateParameter();
            userIdParam.ParameterName = "@UserId";
            userIdParam.DbType = System.Data.DbType.String;
            userIdParam.Size = 36;
            userIdParam.Value = _principalProvider.ClaimsPrincipal.GetObjectId();
            setIsGlobalAdminCommand.Parameters.Add(userIdParam);
            setIsGlobalAdminCommand.ExecuteNonQuery();
        }

        private static bool DoesConnectionNeedAccessToken(SqlConnection connection)
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
