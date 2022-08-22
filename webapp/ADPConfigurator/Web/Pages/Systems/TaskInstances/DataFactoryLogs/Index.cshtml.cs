using System.Collections.Generic;
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

namespace ADPConfigurator.Web.Pages.Systems.TaskInstances.DataFactoryLogs
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

        public IDictionary<string,IList<DataFactoryLog>> DataFactoryLog { get;set; }

        public async Task<ActionResult> OnGetAsync(int taskInstanceId, int systemId, int taskId)
        {
            if (!await _authorizationService.CanAccessSystem(systemId))
            {
                return Forbid();
            }

            ViewData["SystemId"] = systemId;
            ViewData["TaskId"] = taskId;
            var logs = await _context.DataFactoryLog
                .Include(l => l.TaskInstance.Task)
                .Where(l => l.TaskInstanceId == taskInstanceId)
                .OrderBy(l => l.PipelineRunId)
                .ThenByDescending(l => l.DateCreated)
                .ToListAsync();
            DataFactoryLog = new Dictionary<string, IList<DataFactoryLog>>();
            if (logs.Count > 0)
            {
                List<DataFactoryLog> currentRun = new List<DataFactoryLog>();
                DataFactoryLog.Add(logs.First().PipelineRunId, currentRun);
                foreach (var log in logs)
                {
                    if (currentRun.Count > 0 && currentRun[0].PipelineRunId != log.PipelineRunId)
                    {
                        currentRun = new List<DataFactoryLog>();
                        DataFactoryLog.Add(log.PipelineRunId, currentRun);
                    }
                    currentRun.Add(log);
                }
            }

            return Page();
        }
    }
}
