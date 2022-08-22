using System;
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

namespace ADPConfigurator.Web.Pages.Systems.TaskInstances
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
        public PaginatedList<TaskInstance> TaskInstance { get; set; }
        [BindProperty]
        public List<FileLoadLog> FileLoadLog { get; set; }
        [BindProperty]
        public List<IncrementalLoadLog> IncrementalLoadLog { get; set; }
        public async Task<ActionResult> OnGetAsync(int taskId, int systemId, int? taskInstanceId, int? pageIndex, DateTimeOffset? startDateFilter, DateTimeOffset? endDateFilter, DateTimeOffset? currentStartDate, DateTimeOffset? currentEndDate, string searchString, string currentFilter)
        {
            if (!await _authorizationService.CanAccessSystem(systemId))
            {
                return Forbid();
            }
            
            // If taskinstanceId is passed it's a reset request for that instance
            if (taskInstanceId.HasValue)
            {
                var taskInstance = await _context.TaskInstance
                .Include(t => t.TaskResult)
                .FirstOrDefaultAsync(m => m.TaskInstanceId == taskInstanceId);
                // 1 == success, only state they're allowed to retry
                if (taskInstance != null && taskInstance.TaskResultId == 1)
                {
                    // 2 == Failure - Retry, the state we've been requested to set this to
                    taskInstance.TaskResultId = 2;
                    _context.Update(taskInstance).State = EntityState.Modified;

                    //// Get TaskID
                    //var currentTaskId = _context.TaskInstance
                    //    .Where(t => t.TaskInstanceId == taskInstanceId)
                    //    .Select(t => t.TaskId)
                    //    .FirstOrDefault();

                    // update FileLoadLog and set Successful = 0
                    var fileLoadLog = await _context.FileLoadLog
                        .Include(f => f.TaskInstance)
                        .Where(f => f.TaskInstanceId == taskInstanceId)
                        .ToListAsync();
                    
                    foreach(var fileLoadLogItem in fileLoadLog)
                    {
                        fileLoadLogItem.SuccessIndicator = false;
                        _context.Update(fileLoadLogItem).State = EntityState.Modified; 
                    }

                    // update IncrementalLoadLog
                    var incrementalLoadLog = await _context.IncrementalLoadLog
                        .Include(i => i.TaskInstance)
                        .Where(i => i.TaskInstanceId == taskInstanceId)
                        .ToListAsync();

                    foreach(var incrementalLoadLogItem in incrementalLoadLog)
                    {
                        incrementalLoadLogItem.SuccessIndicator = false;
                        _context.Update(incrementalLoadLogItem).State = EntityState.Modified;
                    }

                    await _context.SaveChangesAsync();
                }
            }

            IQueryable<TaskInstance> taskInstanceIQ = _context.TaskInstance
                .Include(t => t.Task.System)
                .Where(t => (taskId == 0 && t.Task.SystemId == systemId) || t.Task.TaskId == taskId)
                .Include(t => t.ScheduleInstance.Schedule)
                .Include(t => t.TaskResult)
                //.GroupBy(t => t.RunDate)
                .OrderByDescending(t => t.RunDate)
                .ThenBy(t => t.Task.TaskName);

            // if startDateFilter or endDateFilter has values then its a new search otherwise it is an existing search
            if (startDateFilter.HasValue || endDateFilter.HasValue)
            {
                pageIndex = 1;
            }
            else
            {
                startDateFilter = currentStartDate;
                endDateFilter = currentEndDate;
            }
            
            if (startDateFilter.HasValue && endDateFilter.HasValue)
            {
                ViewData["CurrentStartDate"] = startDateFilter.Value.Date.Year + "-" + startDateFilter.Value.Date.Month + "-" + startDateFilter.Value.Date.Day;
                ViewData["CurrentEndDate"] = endDateFilter.Value.Date.Year + "-" + endDateFilter.Value.Date.Month + "-" + endDateFilter.Value.Date.Day;
                taskInstanceIQ = taskInstanceIQ.Where(s => DateTimeOffset.Compare(s.DateCreated, startDateFilter.Value) >= 0 && DateTimeOffset.Compare(s.DateCreated, endDateFilter.Value.AddHours(23).AddMinutes(59).AddSeconds(59).AddMilliseconds(59)) <= 0);
            } else if (startDateFilter.HasValue)
            {
                ViewData["CurrentStartDate"] = startDateFilter.Value.Date.Year + "-" + startDateFilter.Value.Date.Month + "-" + startDateFilter.Value.Date.Day;
                taskInstanceIQ = taskInstanceIQ.Where(s => DateTimeOffset.Compare(s.DateCreated, startDateFilter.Value) >= 0); 
            } else if (endDateFilter.HasValue)
            {
                ViewData["CurrentEndDate"] = endDateFilter.Value.Date.Year + "-" + endDateFilter.Value.Date.Month + "-" + endDateFilter.Value.Date.Day;
                taskInstanceIQ = taskInstanceIQ.Where(s => DateTimeOffset.Compare(s.DateCreated, endDateFilter.Value.AddHours(23).AddMinutes(59).AddSeconds(59).AddMilliseconds(59)) <= 0);
            }

            // if searchString is not null then it is a new search, otherwise it is an existing search
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
                taskInstanceIQ = taskInstanceIQ.Where(s => s.Task.TaskName.Contains(searchString)
                || s.ScheduleInstance.Schedule.ScheduleName.Contains(searchString)
                || s.TaskResult.TaskResultName.Contains(searchString));
            }


            // Always reload the list
            ViewData["TaskId"] = taskId;
            ViewData["SystemId"] = systemId;
            if(await taskInstanceIQ.CountAsync() == 0)
            {
                if(taskId==0)
                {
                    ViewData["ListTitle"] = (await _context.System.Where(s => s.SystemId == systemId).SingleOrDefaultAsync()).SystemName;
                }
                else
                {
                    ViewData["ListTitle"] = (await _context.Task.Where(t => t.TaskId == taskId).SingleOrDefaultAsync()).TaskName;
                }
            }

            const int pageSize = 20;
            
            TaskInstance = await PaginatedList<TaskInstance>.CreateAsync(
                taskInstanceIQ.AsNoTracking(), pageIndex ?? 1, pageSize);

            return Page();
        }
    }
}
