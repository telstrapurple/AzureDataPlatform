using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using ADPConfigurator.Domain.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.Identity.Web;

namespace ADPConfigurator.Web.Services
{
    public class SignedInUserProvider
    {
        private PrincipalProvider PrincipalProvider { get; set; }

        private ADS_ConfigContext _dbContext { get; set; }

        public ClaimsPrincipal ClaimsPrincipal { get; }

        public User User { get; }

        public bool IsGlobalAdmin => User?.AdminIndicator ?? false;

        public bool IsLocalAdmin => PrincipalProvider.Groups.Intersect(AdminGroups).Any();

        public bool IsAdmin => IsGlobalAdmin || IsLocalAdmin;

        public bool CanAccessSystem(int systemId)
        {
            if (IsGlobalAdmin) return true;
            return _dbContext.System.Where(
                x => x.SystemId == systemId
                  && (PrincipalProvider.Groups.Contains(x.LocalAdminGroup)
                  || PrincipalProvider.Groups.Contains(x.MemberGroup))
            ).Any();
        }

        public IList<Guid?> AdminGroups { get; set; }

        public SignedInUserProvider(ADS_ConfigContext dbContext, IHttpContextAccessor httpContextAccessor, PrincipalProvider principalProvider)
        {
            _dbContext = dbContext;

            ClaimsPrincipal = httpContextAccessor.HttpContext.User;
            PrincipalProvider = principalProvider;

            EnsureUserFromAzureAdClaims();

            var objectId = ClaimsPrincipal.GetObjectId();
            User = dbContext.User.FirstOrDefault(x => x.UserId == objectId);
            AdminGroups = dbContext.System.Where(x => x.LocalAdminGroup.HasValue).Select(system => system.LocalAdminGroup.Value as Guid?).Distinct().ToList();
        }

        private void EnsureUserFromAzureAdClaims()
        {
            var oid = ClaimsPrincipal.GetObjectId();
            var name = ClaimsPrincipal.FindFirst(claim => claim.Type == "name").Value;
            var emailAddress = ClaimsPrincipal.FindFirst(claim => claim.Type == "preferred_username").Value;

            var existingUser = _dbContext.User.Find(oid);
            if (existingUser != null)
            {
                existingUser.UserName = name;
                existingUser.EmailAddress = emailAddress;
                existingUser.DateModified = DateTimeOffset.Now;
            }
            else
            {
                _dbContext.User.Add(new User
                {
                    UserId = oid,
                    UserName = name,
                    EmailAddress = emailAddress
                });
            }
            _dbContext.SaveChanges();
        }
    }
}
