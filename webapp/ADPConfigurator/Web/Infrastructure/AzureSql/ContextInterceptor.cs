using ADPConfigurator.Domain.Models;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Graph;
using System;
using System.Text.Json;
using ADPConfigurator.Web.ErrorHandlers;
using System.Linq;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using ADPConfigurator.Web.Services;

namespace ADPConfigurator.Web.Infrastructure.AzureSql
{
    /**
     * For every request, set a session variable in our sql connection.
     * This variable contains the user's groups, and drives row level
     * security filters in the database.
     * 
     * This is the core of what controls what a user can and can't see
     * in the application.
     **/
    public class ContextInterceptor
    {
        private readonly RequestDelegate _next;

        public ContextInterceptor(RequestDelegate next)
        {
            _next = next;
        }

        public async System.Threading.Tasks.Task Invoke(HttpContext httpContext, GraphServiceClient graphClient, PrincipalProvider principalProvider, PullSourceStateProvider pullSourceStateProvider)
        {
            IDirectoryObjectGetMemberGroupsCollectionPage groupsResponse;

            try
            {
                groupsResponse = await graphClient.Me.GetMemberGroups(true).Request().PostAsync();
            }
            catch (Exception e)
            {
                await MsalUiRequiredExceptionHandler.OnMsalUiRequiredException(httpContext, e, pullSourceStateProvider.HasPullSource());
                return;
            }
            principalProvider.Groups = groupsResponse.CurrentPage.Select(x => Guid.Parse(x) as Guid?).ToList();
            await _next(httpContext);
        }
    }

    public static class ContextInterceptorMiddlewareExtensions
    {
        public static IApplicationBuilder UseContextInterceptor(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<ContextInterceptor>();
        }
    }
}
 