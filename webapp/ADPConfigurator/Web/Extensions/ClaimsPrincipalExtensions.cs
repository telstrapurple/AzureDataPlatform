using System.Security.Claims;

namespace ADPConfigurator.Web.Extensions
{
    public static class ClaimsPrincipalExtensions
    {
        public static string GetObjectId(this ClaimsPrincipal claimsPrincipal) =>
            claimsPrincipal.FindFirstValue("http://schemas.microsoft.com/identity/claims/objectidentifier");
    }
}
