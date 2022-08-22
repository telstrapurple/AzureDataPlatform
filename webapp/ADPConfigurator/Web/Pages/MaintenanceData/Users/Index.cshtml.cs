using System.Linq;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Web.Pages.MaintenanceData.Users
{
    [Authorize(Policy = AuthorisationPolicies.IsGlobalAdmin)]
    public class IndexModel : PageModel
    {
        private readonly ADS_ConfigContext _context;

        public IndexModel(ADS_ConfigContext context)
        {
            _context = context;
        }
        public PaginatedList<User> Users { get; set; }
        
        public async Task<IActionResult> OnGetAsync(int? pageIndex)
        {
            IQueryable<User> userIq = _context.User
                .OrderBy(s => s.UserName);

            const int pageSize = 20;

            Users = await PaginatedList<User>.CreateAsync(
                userIq.AsNoTracking(), pageIndex ?? 1, pageSize);

            return Page();
        }
    }
}
