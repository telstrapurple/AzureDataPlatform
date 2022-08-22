using System.Linq;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using ADPConfigurator.Web.Extensions;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Web.Pages.Systems
{
    public class DeleteModel : PageModel
    {
        private readonly ADS_ConfigContext _context;
        private readonly IAuthorizationService _authorizationService;

        public DeleteModel(ADS_ConfigContext context, IAuthorizationService authorizationService)
        {
            _context = context;
            _authorizationService = authorizationService;
        }

        [BindProperty]
        public ADPConfigurator.Domain.Models.System System { get; set; }

        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null) return NotFound();
            if (!await _authorizationService.CanAccessSystem((int)id))
            {
                return Forbid();
            }


            System = await _context.System.FirstOrDefaultAsync(m => m.SystemId == id);

            if (System == null) return NotFound();
            
            return Page();
        }

        public async Task<IActionResult> OnPostAsync(int? id)
        {
            if (id == null) return NotFound();
            if (!await _authorizationService.CanAccessSystem((int)id))
            {
                return Forbid();
            }

            System = await _context.System.FindAsync(id);

            if (System != null)
            {
                System.DeletedIndicator = true;

                var permissionsForSystem = _context.UserPermission.Where(x => x.SystemId == id).ToList();
                permissionsForSystem.ForEach(p => _context.UserPermission.Remove(p));

                await _context.SaveChangesAsync();
            }

            return RedirectToPage("./Index");
        }
    }
}
