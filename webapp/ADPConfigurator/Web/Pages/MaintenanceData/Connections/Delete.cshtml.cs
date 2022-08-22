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
    public class DeleteModel : PageModel
    {
        private readonly ADS_ConfigContext _context;

        public DeleteModel(ADS_ConfigContext context, SignedInUserProvider signedInUserProvider)
        {
            _context = context;
        }

        [BindProperty]
        public Connection Connection { get; set; }

        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            Connection = await _context.Connection
                .Include(c => c.ConnectionType).FirstOrDefaultAsync(m => m.ConnectionId == id);

            if (Connection == null)
            {
                return NotFound();
            }
            return Page();
        }

        public async Task<IActionResult> OnPostAsync(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            Connection = await _context.Connection.FindAsync(id);

            if (Connection != null)
            {
                Connection.DeletedIndicator = true;
                _context.Entry(Connection).State = EntityState.Modified;
                await _context.SaveChangesAsync();
            }

            return RedirectToPage("./Index");
        }
    }
}
