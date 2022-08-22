using System.Security.Claims;
using System.Threading.Tasks;
using ADPConfigurator.Web.Authorisation;
using Microsoft.AspNetCore.Authorization;

namespace ADPConfigurator.Web.Extensions
{
    public static class AuthorizationServiceExtensions
    {
        public static async Task<bool> IsAuthorized(this IAuthorizationService authorizationService, ClaimsPrincipal user, object resource, string policyName)
        {
            var authorizationResult = await authorizationService.AuthorizeAsync(user, resource, policyName);
            return authorizationResult.Succeeded;
        }

        public static Task<bool> CanAccessSystem(this IAuthorizationService authorizationService, int systemId)
        {
            // We don't use this in the handler, so new up a dumb one
            var user = new ClaimsPrincipal(new ClaimsIdentity());

            // This is fixed for this method
            const string policyName = AuthorisationPolicies.CanAccessSystem;

            return authorizationService.IsAuthorized(user, systemId, policyName);
        }
    }
}