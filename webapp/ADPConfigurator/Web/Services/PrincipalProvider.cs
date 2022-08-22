using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System;

namespace ADPConfigurator.Web.Services
{
    public class PrincipalProvider
    {
        public IList<Guid?> Groups { get; set; }

        public ClaimsPrincipal ClaimsPrincipal { get; }

        public PrincipalProvider(IHttpContextAccessor httpContextAccessor)
        {
            ClaimsPrincipal = httpContextAccessor.HttpContext.User;
        }
    }
}
