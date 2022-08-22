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

namespace ADPConfigurator.Web.Pages.Systems.Tasks
{
    public class IndexModel : PageModel
    {
        private readonly ADS_ConfigContext _context;
        private readonly IAuthorizationService _authorizationService;

        public IndexModel(ADS_ConfigContext context, IAuthorizationService authorizationService)
        {
            _context = context;
            _authorizationService = authorizationService;
        }

        public Domain.Models.System System { get; set; }
        public PaginatedList<Domain.Models.Task> Task { get; set; }
        public async Task<ActionResult> OnGetAsync(int systemId, int? pageIndex, string searchString, string currentFilter)
        {
            if (!await _authorizationService.CanAccessSystem(systemId))
            {
                return Forbid();
            }
            
            System = await _context.System.FirstOrDefaultAsync(s => s.SystemId == systemId);
            IQueryable<Domain.Models.Task> taskIQ = _context.Task
                .Where(t => !t.DeletedIndicator)
                .Include(t => t.System)
                .Where(t => systemId == 0 || t.System.SystemId == systemId)
                .Include(t => t.Schedule)
                .Include(t => t.SourceConnection)
                .Include(t => t.TargetConnection)
                .Include(t => t.TaskType)
                .OrderByDescending(t => t.EnabledIndicator)
                .ThenBy(t => t.TaskName)
                .ThenBy(t => t.TaskOrderId);

            if (searchString != null)
            {
                pageIndex = 1;

            } else
            {
                searchString = currentFilter; 
            }

            ViewData["CurrentFilter"] = searchString;

            if (!string.IsNullOrEmpty(searchString))
            {
                taskIQ = taskIQ.Where(s => s.TaskName.Contains(searchString) 
                || s.TaskDescription.Contains(searchString) 
                || s.TaskType.TaskTypeName.Contains(searchString)
                || s.SourceConnection.ConnectionName.Contains(searchString)
                || s.TargetConnection.ConnectionName.Contains(searchString) 
                || s.Schedule.ScheduleName.Contains(searchString)
                || s.TaskOrderId.ToString().Contains(searchString));
            }

            ViewData["SystemId"] = systemId;
            const int pageSize = 20;

            Task = await PaginatedList<Domain.Models.Task>.CreateAsync(
                taskIQ.AsNoTracking(), pageIndex ?? 1, pageSize);

            return Page();
        }
    }
}
