using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using ADPConfigurator.Web.Extensions;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Web.Pages.Systems.Tasks
{
    public class CreateModel : PageModel
    {
        private readonly ADS_ConfigContext _context;
        private readonly IAuthorizationService _authorizationService;

        public CreateModel(ADS_ConfigContext context, IAuthorizationService authorizationService)
        {
            _context = context;
            _authorizationService = authorizationService;
        }

        [BindProperty]
        public Domain.Models.Task Task { get; set; }
        [BindProperty]
        public List<TaskProperty> CurrentTaskProperties { get; set; }
        [BindProperty]
        public List<FileColumnMapping> FileColumnMappings { get; set; }
        [BindProperty]
        public List<TaskPropertyPassthroughMapping> TaskPropertyPassthroughMappings { get; set; }
        [BindProperty]
        public List<TaskPropertyTypeOption> TaskPropertyTypeOptions { get; set; }

        public async Task<IActionResult> OnGetAsync(int id, int? cloneTaskId)
        {
            if (!await _authorizationService.CanAccessSystem(id))
            {
                return Forbid();
            }

            var system = await _context.System.FirstOrDefaultAsync(m => m.SystemId == id);

            Task = new Domain.Models.Task
            {
                SystemId = id, 
                System = system
            };

            CurrentTaskProperties = new List<TaskProperty>();
            TaskPropertyTypeOptions = _context.TaskPropertyTypeOption
                .Where(t => !t.DeletedIndicator)
                .ToList();
            
            // Only show non-deleted
            var allTypes = await _context.TaskPropertyType
                .Include(t => t.TaskPropertyTypeValidation)
                .OrderBy(t => t.TaskPropertyTypeName)
                .ToListAsync();
            
            foreach (var type in allTypes)
            {
                var matchingTaskProp = new TaskProperty();
                matchingTaskProp.TaskPropertyTypeId = type.TaskPropertyTypeId;
                matchingTaskProp.TaskPropertyType = type;
                matchingTaskProp.TaskPropertyType.TaskPropertyTypeValidationId = type.TaskPropertyTypeValidationId;
                matchingTaskProp.TaskPropertyType.TaskPropertyTypeValidation.TaskPropertyTypeValidationName = type.TaskPropertyTypeValidation.TaskPropertyTypeValidationName;
                CurrentTaskProperties.Add(matchingTaskProp);
            }
            
            if (cloneTaskId.HasValue)
            {
                var cloneTask = await _context.Task.Include(t => t.TaskProperty).FirstOrDefaultAsync(m => m.TaskId == cloneTaskId.Value);
                if (cloneTask != null)
                {
                    Task.TaskName = cloneTask.TaskName;
                    Task.TaskDescription = cloneTask.TaskDescription;
                    Task.TaskTypeId = cloneTask.TaskTypeId;
                    Task.ScheduleId = cloneTask.ScheduleId;
                    Task.SourceConnectionId = cloneTask.SourceConnectionId;
                    Task.EtlconnectionId = cloneTask.EtlconnectionId;
                    Task.StageConnectionId = cloneTask.StageConnectionId;
                    Task.TargetConnectionId = cloneTask.TargetConnectionId;
                    Task.EnabledIndicator = true;
                    foreach(var oldProp in cloneTask.TaskProperty.Where(t => !t.DeletedIndicator))
                    {
                        // Going out on a limb here... shouldn't NOT have a taskproptype already setup
                        var matchingProp = (from p in CurrentTaskProperties where p.TaskPropertyTypeId == oldProp.TaskPropertyTypeId select p).Single();
                        matchingProp.TaskPropertyTypeId = oldProp.TaskPropertyTypeId;
                        matchingProp.TaskPropertyValue = oldProp.TaskPropertyValue;

                        // Special case: We prepend this string on the way to the db.
                        // We need to remove that prefix on the way into the UI, otherwise we'll double
                        // the prefix
                        if (matchingProp.TaskPropertyType.TaskPropertyTypeName == "Target File Path")
                        {
                            matchingProp.TaskPropertyValue = matchingProp.TaskPropertyValue.Replace(Task.System.TargetPathPrefix, string.Empty);
                        }
                        Task.TaskProperty.Add(matchingProp);
                    }
                }
            }
            
            ViewData["ScheduleId"] = new SelectList(_context.Schedule.Where(s => !s.DeletedIndicator), "ScheduleId", "ScheduleName");
            ViewData["SystemId"] = new SelectList(_context.System.Where(s => !s.DeletedIndicator), "SystemId", "SystemName");
            // Source Connection
            List<SelectListItem> SourceConnectionIdList = new SelectList(_context.Connection.Where(c => !c.DeletedIndicator), "ConnectionId", "ConnectionName").ToList();
            ViewData["SourceConnectionId"] = SourceConnectionIdList;
            // Target Connection
            List<SelectListItem> TargetConnectionIdList = new SelectList(_context.Connection.Where(c => !c.DeletedIndicator), "ConnectionId", "ConnectionName").ToList();
            TargetConnectionIdList.Insert(0, new SelectListItem() { Value = "0", Text = "(none)" });
            ViewData["TargetConnectionId"] = TargetConnectionIdList;
            // ETL Connection
            List<SelectListItem> EtlconnectionIdList = new SelectList(_context.Connection.Where(c => !c.DeletedIndicator), "ConnectionId", "ConnectionName").ToList();
            EtlconnectionIdList.Insert(0, new SelectListItem() { Value = "0", Text = "(none)" });
            ViewData["EtlconnectionId"] = EtlconnectionIdList;
            // Stage Connection
            List<SelectListItem> StageConnectionId = new SelectList(_context.Connection.Where(c => !c.DeletedIndicator), "ConnectionId", "ConnectionName").ToList();
            StageConnectionId.Insert(0, new SelectListItem() { Value = "0", Text = "(none)" });
            ViewData["StageConnectionId"] = StageConnectionId;
            
            ViewData["TaskTypeId"] = new SelectList(_context.TaskType.Where(t => !t.DeletedIndicator && t.EnabledIndicator), "TaskTypeId", "TaskTypeName");
            ViewData["TaskPropertyTypeId"] = new SelectList(_context.TaskPropertyType, "TaskPropertyTypeId", "TaskPropertyTypeName");
            ViewData["FileInterimDataTypeId"] = new SelectList(_context.FileInterimDataType.Where(f => !f.DeletedIndicator), "FileInterimDataTypeId", "FileInterimDataTypeName");
            ViewData["FileInterimDataTypeItems"] = JsonSerializer.Serialize(_context.FileInterimDataType.Where(f => !f.DeletedIndicator).Select(f => new { id = f.FileInterimDataTypeId, name = f.FileInterimDataTypeName }).ToList()).ToString();
            try
            {
                ViewData["FileColumnMappingsIndex"] = _context.FileColumnMapping.Max(f => f.FileColumnMappingId);
            }
            catch
            {
                ViewData["FileColumnMappingsIndex"] = 0;
            }
            ViewData["TaskTypeTaskPropertyTypeMapping"] = JsonSerializer.Serialize(_context.TaskTypeTaskPropertyTypeMapping.Where(t => !t.DeletedIndicator).Select(t => new { taskTypeId = t.TaskTypeId, taskPropertyTypeId = t.TaskPropertyTypeId }).ToList()).ToString();
            ViewData["ConnectionType"] = JsonSerializer.Serialize(_context.Connection.Where(t => !t.DeletedIndicator).Include(t => t.ConnectionType).Select(t => new { connectionId = t.ConnectionId , connectionTypeId = t.ConnectionTypeId, databaseConnectionIndicator = t.ConnectionType.DatabaseConnectionIndicator, fileConnectionIndicator = t.ConnectionType.FileConnectionIndicator}).ToList()).ToString();
            ViewData["Tasks"] = JsonSerializer.Serialize(_context.Task.Include(t => t.System).Where(t => !t.DeletedIndicator && t.TaskName != Task.TaskName).Select(t => new { taskId = t.TaskId, taskName = t.System.SystemName + "." + t.TaskName }).ToList()).ToString();
            try
            {
                ViewData["TaskPropertyPassthroughMappingIndex"] = _context.TaskPropertyPassthroughMapping.Max(t => t.TaskPropertyPassthroughMappingId);
            }
            catch
            {
                ViewData["TaskPropertyPassthroughMappingIndex"] = 0;
            }
            
            ViewData["TaskType"] = JsonSerializer.Serialize(_context.TaskType.Where(t => !t.DeletedIndicator).Select(t => new { taskTypeId = t.TaskTypeId, taskTypeName = t.TaskTypeName, scriptIndicator = t.ScriptIndicator, databaseLoadIndicator = t.DatabaseLoadIndicator, fileLoadIndicator = t.FileLoadIndicator }).ToList()).ToString();
            // ViewData["TaskPropertyTypeOption"] = new SelectList(_context.TaskPropertyTypeOption, "TaskPropertyTypeId", "TaskPropertyTypeOptionId", "TaskPropertyTypeOptionName");
            // ViewData["TaskPropertyTypeOption"] = new List<TaskPropertyTypeOption>();
            // ViewData["TaskPropertyTypeOption"] = new SelectList(_context.TaskPropertyTypeOption, "TaskPropertyTypeOptionId", "TaskPropertyTypeOptionName");
            //ViewData["TaskPropertyTypeOption"] = _context.TaskPropertyTypeOption.ToList();

            return Page();
        }

        // To protect from overposting attacks, please enable the specific properties you want to bind to, for
        // more details see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid) return Page();
            if (!await _authorizationService.CanAccessSystem(Task.SystemId))
            {
                return Forbid();
            }

            if (Task.EtlconnectionId == 0 )
            {
                Task.EtlconnectionId = null;
            }
            if (Task.StageConnectionId == 0)
            {
                Task.StageConnectionId = null;
            }
            if (Task.TargetConnectionId == 0)
            {
                Task.TargetConnectionId = null;
            }

            _context.Task.Add(Task);
            // Process task properties 
            foreach (var property in CurrentTaskProperties)
            {
                if (!string.IsNullOrWhiteSpace(property.TaskPropertyValue))
                {
                    property.TaskId = Task.TaskId;
                    var taskPropertyType = _context.TaskPropertyType.Find(property.TaskPropertyTypeId);
                    // Special case: We prepend this value with a computed value to prevent users
                    // from affecting other systems
                    if (taskPropertyType.TaskPropertyTypeName == "Target File Path")
                    {
                        var system = _context.System.Find(Task.SystemId);
                        property.TaskPropertyValue = system.TargetPathPrefix + property.TaskPropertyValue;
                    }
                    Task.TaskProperty.Add(property);
                }
            }
            foreach (var fileColumnMapping in FileColumnMappings)
            {
                if (!string.IsNullOrWhiteSpace(fileColumnMapping.SourceColumnName) || !string.IsNullOrWhiteSpace(fileColumnMapping.TargetColumnName))
                {
                    // this is a new item 
                    var newFileColumnMapping = new FileColumnMapping();
                    newFileColumnMapping.TaskId = Task.TaskId;
                    newFileColumnMapping.SourceColumnName = fileColumnMapping.SourceColumnName;
                    newFileColumnMapping.TargetColumnName = fileColumnMapping.TargetColumnName;
                    newFileColumnMapping.FileInterimDataTypeId = fileColumnMapping.FileInterimDataTypeId;
                    newFileColumnMapping.DataLength = fileColumnMapping.DataLength;
                    newFileColumnMapping.DeletedIndicator = fileColumnMapping.DeletedIndicator;
                    Task.FileColumnMapping.Add(newFileColumnMapping);
                }
            }

            foreach (var taskPropertyPassthroughMapping in TaskPropertyPassthroughMappings)
            {
                // this is a new item 
                var newTaskPropertyPassthroughMapping = new TaskPropertyPassthroughMapping();
                newTaskPropertyPassthroughMapping.TaskId = Task.TaskId;
                newTaskPropertyPassthroughMapping.TaskPassthroughId = taskPropertyPassthroughMapping.TaskPassthroughId;
                Task.TaskPropertyPassthroughMappingTask.Add(newTaskPropertyPassthroughMapping);
            }

            await _context.SaveChangesAsync();
            int systemId = Task.SystemId;
            return Redirect($"../Index?systemId={systemId}");
        }
    }
}
