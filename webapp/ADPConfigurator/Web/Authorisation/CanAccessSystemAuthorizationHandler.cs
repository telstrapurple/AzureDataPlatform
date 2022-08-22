using System.Threading.Tasks;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;

namespace ADPConfigurator.Web.Authorisation
{
    public class CanAccessSystemRequirement : IAuthorizationRequirement
    {
    }
    
    public class CanAccessSystemAuthorizationHandler : AuthorizationHandler<CanAccessSystemRequirement, int>
    {
        private readonly SignedInUserProvider _signedInUserProvider;

        public CanAccessSystemAuthorizationHandler(SignedInUserProvider signedInUserProvider)
        {
            _signedInUserProvider = signedInUserProvider;
        }

        protected override Task HandleRequirementAsync(
            AuthorizationHandlerContext context, 
            CanAccessSystemRequirement requirement, 
            int systemId)
        {
            if (_signedInUserProvider.CanAccessSystem(systemId))
            {
                context.Succeed(requirement);
            }
            return Task.CompletedTask;
        }
    }
}