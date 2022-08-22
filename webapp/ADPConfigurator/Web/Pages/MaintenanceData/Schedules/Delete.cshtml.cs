using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Web.Pages.MaintenanceData.Schedules
{
    [Authorize(Policy = AuthorisationPolicies.IsAdmin)]
    public class DeleteModel : PageModel
    {
        private readonly ADS_ConfigContext _context;

        public DeleteModel(ADS_ConfigContext context, SignedInUserProvider signedInUserProvider)
        {
            _context = context;
        }

        [BindProperty]
        public Schedule Schedule { get; set; }

        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null) return NotFound();

            Schedule = await _context.Schedule
                .Include(s => s.ScheduleInterval).FirstOrDefaultAsync(m => m.ScheduleId == id);

            if (Schedule == null)
            {
                return NotFound();
            }
            return Page();
        }

        public async Task<IActionResult> OnPostAsync(int? id)
        {
            if (id == null) return NotFound();

            Schedule = await _context.Schedule.FindAsync(id);

            if (Schedule != null)
            {
                Schedule.DeletedIndicator = true;
                _context.Entry(Schedule).State = EntityState.Modified;
                await _context.SaveChangesAsync();
            }

            return RedirectToPage("./Index");
        }
    }
}
