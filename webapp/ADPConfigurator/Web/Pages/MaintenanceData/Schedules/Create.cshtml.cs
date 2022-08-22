using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ADPConfigurator.Web.Pages.MaintenanceData.Schedules
{
    [Authorize(Policy = AuthorisationPolicies.IsAdmin)]
    public class CreateModel : PageModel
    {
        private readonly ADS_ConfigContext _context;

        public CreateModel(ADS_ConfigContext context)
        {
            _context = context;
        }

        public IActionResult OnGet()
        {
            ViewData["ScheduleIntervalId"] = new SelectList(_context.ScheduleInterval, "ScheduleIntervalId", "ScheduleIntervalName");
            return Page();
        }

        [BindProperty]
        public Schedule Schedule { get; set; }

        // To protect from overposting attacks, please enable the specific properties you want to bind to, for
        // more details see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid) return Page(); 

            _context.Schedule.Add(Schedule);
            await _context.SaveChangesAsync();

            return RedirectToPage("./Index");
        }
    }
}
