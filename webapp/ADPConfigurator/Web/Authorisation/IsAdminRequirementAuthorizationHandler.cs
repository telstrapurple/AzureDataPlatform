using System.Threading.Tasks;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;

namespace ADPConfigurator.Web.Authorisation
{
    public class IsAdminRequirement : IAuthorizationRequirement
    {
    }
    
    public class IsAdminAuthorizationHandler : AuthorizationHandler<IsAdminRequirement>
    {
        private readonly SignedInUserProvider _signedInUserProvider;

        public IsAdminAuthorizationHandler(SignedInUserProvider signedInUserProvider)
        {
            _signedInUserProvider = signedInUserProvider;
        }

        protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, IsAdminRequirement requirement)
        {
            if (_signedInUserProvider.IsAdmin)
            {
                context.Succeed(requirement);
            }
            return Task.CompletedTask;
        }
    }
}