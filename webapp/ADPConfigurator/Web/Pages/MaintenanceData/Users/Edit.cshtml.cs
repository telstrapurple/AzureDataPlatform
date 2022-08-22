using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using Microsoft.ApplicationInsights.AspNetCore.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Web.Pages.MaintenanceData.Users
{
    [Authorize(Policy = AuthorisationPolicies.IsGlobalAdmin)]
    public class EditModel : PageModel
    {
        private readonly ADS_ConfigContext _context;
        private string _currentUserOid;
        public User SelectedUser { get; set; }
        public bool IsSelf => SelectedUser.UserId == _currentUserOid;

        public EditModel(ADS_ConfigContext context)
        {
            _context = context;
        }

        private async System.Threading.Tasks.Task Initialise(string userId)
        {
            var identity = User.Identity as ClaimsIdentity;
            _currentUserOid = identity.Claims.FirstOrDefault(claim => claim.Type == "http://schemas.microsoft.com/identity/claims/objectidentifier")?.Value;

            SelectedUser = await _context
                .User
                .FirstAsync(x => x.UserId == userId);

            if (SelectedUser == null) return;
        }

        public async Task<IActionResult> OnGetAsync(string userId)
        {
            await Initialise(userId);

            return Page();
        }

        public async Task<IActionResult> OnPostAsync(string userId)
        {
            await Initialise(userId);

            if (!IsSelf)
            {
                SelectedUser.AdminIndicator = Request.Form["AdminIndicator"] == "true";
            }

            await _context.SaveChangesAsync();
            
            // Redirect to the GET action, so that if the user reloads the browser, they don't get prompted to resubmit
            // the form data.
            return Redirect(Request.GetUri().ToString());
        }
    }
}
