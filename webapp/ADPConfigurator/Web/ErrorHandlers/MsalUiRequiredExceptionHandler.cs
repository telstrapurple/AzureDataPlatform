using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Http;
using Microsoft.Identity.Client;
using Microsoft.Identity.Web;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using System;
using System.Linq;
using System.Security.Claims;

namespace ADPConfigurator.Web.ErrorHandlers
{
    public class MsalUiRequiredExceptionHandler
    {
        /// <summary>
        /// Calling a downstream api that is protected by microsoft identity can throw an exception that needs to be carefully handled.
        /// Microsoft.Identity.Web.UI provides an attribute you can decorate your razor pages with
        /// to handle this for you. No such helper exists for middleware, so we have to handle it
        /// ourselves.
        /// 
        /// The handling logic here is based entirely on that attribute in Microsoft.Identity.Web.UI,
        /// which you can find here:
        /// https://github.com/AzureAD/microsoft-identity-web/blob/c95d8801f35ecf01a144c25b2c3f8b598be7c95e/src/Microsoft.Identity.Web/AuthorizeForScopesAttribute.cs#L56
        /// </summary>
        public static async System.Threading.Tasks.Task OnMsalUiRequiredException(HttpContext httpContext, Exception exception, bool hasPullSource)
        {
            MsalUiRequiredException? msalUiRequiredException = FindMsalUiRequiredExceptionIfAny(exception);
            if (msalUiRequiredException == null || (!msalUiRequiredException.ErrorCode.Contains(MsalError.UserNullError) && !msalUiRequiredException.ErrorCode.Contains(MsalError.InvalidGrantError)))
            {
                throw exception;
            }

            string[] scopes = {
                "openid",
                "offline_access",
                "profile",
                "user.read"
            };

            HttpRequest httpRequest;
            ClaimsPrincipal user;

            lock (httpContext)
            {
                httpRequest = httpContext.Request;
                user = httpContext.User;
            }

            AuthenticationProperties properties = new AuthenticationProperties();
            properties.SetParameter("scope", scopes.ToList());

            var loginHint = user.GetLoginHint();
            if (!string.IsNullOrWhiteSpace(loginHint))
            {
                properties.SetParameter(OpenIdConnectParameterNames.LoginHint, loginHint);

                var domainHint = user.GetDomainHint();
                properties.SetParameter(OpenIdConnectParameterNames.DomainHint, domainHint);
            }

            await httpContext.ChallengeAsync(properties);
        }

        private static MsalUiRequiredException? FindMsalUiRequiredExceptionIfAny(Exception exception)
        {
            MsalUiRequiredException? msalUiRequiredException = exception as MsalUiRequiredException;
            if (msalUiRequiredException != null)
            {
                return msalUiRequiredException;
            }
            else if (exception.InnerException != null)
            {
                return FindMsalUiRequiredExceptionIfAny(exception.InnerException);
            }
            else
            {
                return null;
            }
        }
    }
}
