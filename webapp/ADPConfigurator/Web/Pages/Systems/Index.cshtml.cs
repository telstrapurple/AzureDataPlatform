using System.Linq;
using ADPConfigurator.Domain.Models;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Microsoft.Identity.Web;

namespace ADPConfigurator.Web.Pages.Systems
{
    [AuthorizeForScopes(ScopeKeySection = "PullSource:Scopes")]
    public class IndexModel : PageModel
    {
        private readonly ADS_ConfigContext _context;

        public IndexModel(ADS_ConfigContext context)
        {
            _context = context;
        }

        public PaginatedList<Domain.Models.System> System { get; set; }

        public async System.Threading.Tasks.Task OnGetAsync(int? pageIndex, string searchString, string currentFilter)
        {
            IQueryable<Domain.Models.System> systemIQ = _context.System
                .Where(s => !s.DeletedIndicator)
                .OrderByDescending(s => s.EnabledIndicator)
                .ThenBy(s => s.SystemCode)
                .ThenBy(s => s.SystemName);
            
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
                systemIQ = systemIQ.Where(s => s.SystemCode.Contains(searchString)
                || s.SystemName.Contains(searchString));
            }

            const int pageSize = 20;

            System = await PaginatedList<Domain.Models.System>.CreateAsync(
                systemIQ.AsNoTracking(), pageIndex ?? 1, pageSize);
        }
    }
}
