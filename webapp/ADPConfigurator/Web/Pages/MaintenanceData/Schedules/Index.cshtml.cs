using System.Linq;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Web.Pages.MaintenanceData.Schedules
{
    [Authorize(Policy = AuthorisationPolicies.IsAdmin)]
    public class IndexModel : PageModel
    {
        private readonly ADS_ConfigContext _context;

        public IndexModel(ADS_ConfigContext context)
        {
            _context = context;
        }
        public PaginatedList<Schedule> Schedule { get; set; }

        public async Task<IActionResult> OnGetAsync(int? pageIndex, string searchString, string currentFilter)
        {
            IQueryable<Schedule> scheduleIQ = _context.Schedule
                .Where(s => !s.DeletedIndicator)
                .Include(s => s.ScheduleInterval)
                .OrderByDescending(s => s.EnabledIndicator)
                .ThenBy(s => s.ScheduleName);

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
                scheduleIQ = scheduleIQ.Where(s => s.ScheduleName.Contains(searchString)
                || s.ScheduleInterval.ScheduleIntervalName.Contains(searchString)
                || s.Frequency.ToString().Contains(searchString));
            }

            int pageSize = 20;

            Schedule = await PaginatedList<Schedule>.CreateAsync(
                scheduleIQ.AsNoTracking(), pageIndex ?? 1, pageSize);

            return Page();
        }
    }
}
