using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Web.Pages.MaintenanceData.GenericConfigs
{
    [Authorize(Policy = AuthorisationPolicies.IsGlobalAdmin)]
    public class IndexModel : PageModel
    {
        private readonly ADS_ConfigContext _context;

        public IndexModel(ADS_ConfigContext context)
        {
            _context = context;
        }
        
        [BindProperty]
        public IList<GenericConfig> GenericConfig { get;set; }

        public async Task<IActionResult> OnGetAsync()
        {
            GenericConfig = await _context.GenericConfig
                .OrderBy(c => c.GenericConfigName)
                .ToListAsync();

            return Page();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid) return Page();
            
            foreach (var configValue in GenericConfig)
            {
                _context.Entry(configValue).State = EntityState.Modified;
            }

            await _context.SaveChangesAsync();
            
            return RedirectToPage("./Index");
        }
    }
}
