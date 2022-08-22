using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using ADPConfigurator.Web.Extensions;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Web.Pages.Systems.Tasks
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
        public Domain.Models.Task Task { get; set; }

        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null) return NotFound();

            Task = await _context.Task
                .Include(t => t.Schedule)
                .Include(t => t.SourceConnection)
                .Include(t => t.Etlconnection)
                .Include(t => t.StageConnection)
                .Include(t => t.System)
                .Include(t => t.TargetConnection)
                .Include(t => t.TaskType).FirstOrDefaultAsync(m => m.TaskId == id);

            if (Task == null) return NotFound();
            
            if (!await _authorizationService.CanAccessSystem(Task.SystemId))
            {
                return Forbid();
            }
            
            return Page();
        }

        public async Task<IActionResult> OnPostAsync(int? id)
        {
            if (id == null) return NotFound();

            Task = await _context.Task.FindAsync(id);

            if (!await _authorizationService.CanAccessSystem(Task.SystemId))
            {
                return Forbid();
            }

            if (Task != null)
            {
                int systemId = Task.SystemId;
                Task.DeletedIndicator = true;
                _context.Entry(Task).State = EntityState.Modified;
                await _context.SaveChangesAsync();

                return Redirect($"./Index?systemid={systemId}");
            }

            return RedirectToPage("../Index");
        }
    }
}
