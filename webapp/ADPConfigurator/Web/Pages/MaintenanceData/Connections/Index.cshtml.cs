using System.Linq;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Web.Pages.MaintenanceData.Connections
{
    [Authorize(Policy = AuthorisationPolicies.IsAdmin)]
    public class IndexModel : PageModel
    {
        private readonly ADS_ConfigContext _context;

        public IndexModel(ADS_ConfigContext context, SignedInUserProvider signedInUserProvider)
        {
            _context = context;
        }
        public PaginatedList<Connection> Connection { get; set; }

        public async Task<IActionResult> OnGetAsync(int? pageIndex, string searchString, string currentFilter)
        {
            IQueryable<Connection> connectionIQ = _context.Connection
                .Where(c => !c.DeletedIndicator)
                .Include(c => c.ConnectionType)
                .OrderByDescending(c => c.EnabledIndicator)
                .ThenBy(c => c.ConnectionName);

            if (searchString != null)
            {
                pageIndex = 1;

            }
            else
            {
                searchString = currentFilter;
            }

            ViewData["CurrentFilter"] = searchString;

            if (!string.IsNullOrEmpty(searchString))
            {
                connectionIQ = connectionIQ.Where(s => s.ConnectionName.Contains(searchString)
                || s.ConnectionType.ConnectionTypeName.Contains(searchString));
            }


            int pageSize = 20;

            Connection = await PaginatedList<Connection>.CreateAsync(
                connectionIQ.AsNoTracking(), pageIndex ?? 1, pageSize);

            return Page();
        }
    }
}
