using System.Threading.Tasks;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;

namespace ADPConfigurator.Web.Authorisation
{
    public class IsGlobalAdminRequirement : IAuthorizationRequirement
    {
    }
    
    public class IsGlobalAdminAuthorizationHandler : AuthorizationHandler<IsGlobalAdminRequirement>
    {
        private readonly SignedInUserProvider _signedInUserProvider;

        public IsGlobalAdminAuthorizationHandler(SignedInUserProvider signedInUserProvider)
        {
            _signedInUserProvider = signedInUserProvider;
        }

        protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, IsGlobalAdminRequirement requirement)
        {
            if (_signedInUserProvider.IsGlobalAdmin)
            {
                context.Succeed(requirement);
            }
            return Task.CompletedTask;
        }
    }
}