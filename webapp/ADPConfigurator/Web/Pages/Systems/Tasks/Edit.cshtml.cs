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
    public class EditModel : PageModel
    {
        private readonly ADS_ConfigContext _context;
        private readonly IAuthorizationService _authorizationService;

        public EditModel(ADS_ConfigContext context, IAuthorizationService authorizationService)
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
        public List<SelectListItem> FileInterimDataTypes { get; set; }
        [BindProperty]
        public List<TaskPropertyPassthroughMapping> TaskPropertyPassthroughMappings { get; set; }
        [BindProperty]
        public List<SelectListItem> Tasks { get; set; }

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
                .Include(t => t.TaskType)
                .Include(t => t.TaskProperty)
                .FirstOrDefaultAsync(m => m.TaskId == id);
            
            if (Task == null) return NotFound();
            
            if (!await _authorizationService.CanAccessSystem(Task.SystemId))
            {
                return Forbid();
            }

            // Only show non-deleted
            var allTypes = await _context.TaskPropertyType
                .Include(t => t.TaskPropertyTypeValidation)
                .OrderBy(t => t.TaskPropertyTypeName)
                .ToListAsync();
            CurrentTaskProperties = new List<TaskProperty>();
            TaskPropertyTypeOptions = _context.TaskPropertyTypeOption.Where(t => !t.DeletedIndicator).ToList();
            foreach (var type in allTypes)
            {
                var matchingTaskProp = (from p in Task.TaskProperty where p.TaskPropertyTypeId == type.TaskPropertyTypeId select p).SingleOrDefault();
                // Bit complicated. If it's been cleared/deleted previously then treat it as new, however when posting if a value is set then 'un-delete' the existing record and overwrite the value
                if (matchingTaskProp == null || matchingTaskProp.DeletedIndicator)
                {
                    matchingTaskProp = new TaskProperty();
                    // -1 id properties are for insertion (if set)
                    matchingTaskProp.TaskPropertyId = -1;
                    matchingTaskProp.TaskPropertyTypeId = type.TaskPropertyTypeId;
                }
                matchingTaskProp.TaskPropertyType = type;
                matchingTaskProp.TaskPropertyType.TaskPropertyTypeValidationId = type.TaskPropertyTypeValidationId;
                matchingTaskProp.TaskPropertyType.TaskPropertyTypeValidation.TaskPropertyTypeValidationName = type.TaskPropertyTypeValidation.TaskPropertyTypeValidationName;

                // Special case: We prepend this string on the way to the db.
                // We need to remove that prefix on the way into the UI, otherwise we'll double
                // the prefix
                if (matchingTaskProp.TaskPropertyType.TaskPropertyTypeName == "Target File Path" && matchingTaskProp.TaskPropertyValue != null)
                {
                    matchingTaskProp.TaskPropertyValue = matchingTaskProp.TaskPropertyValue.Replace(Task.System.TargetPathPrefix, string.Empty);
                }
                CurrentTaskProperties.Add(matchingTaskProp);
            }
            ViewData["ScheduleId"] = new SelectList(_context.Schedule.Where(s => !s.DeletedIndicator), "ScheduleId", "ScheduleName");
            ViewData["SystemId"] = new SelectList(_context.System.Where(s => !s.DeletedIndicator), "SystemId", "SystemName");
            ViewData["TaskTypeId"] = new SelectList(_context.TaskType.Where(t => !t.DeletedIndicator && t.EnabledIndicator), "TaskTypeId", "TaskTypeName");
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

            // ViewData["FileInterimDataTypeId"] = new SelectList(_context.FileInterimDataType.Where(f => !f.DeletedIndicator), "FileInterimDataTypeId", "FileInterimDataTypeName");
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
            ViewData["ConnectionType"] = JsonSerializer.Serialize(_context.Connection.Where(t => !t.DeletedIndicator).Include(t => t.ConnectionType).Select(t => new { connectionId = t.ConnectionId, connectionTypeId = t.ConnectionTypeId, databaseConnectionIndicator = t.ConnectionType.DatabaseConnectionIndicator, fileConnectionIndicator = t.ConnectionType.FileConnectionIndicator }).ToList()).ToString();
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

            // Get file column mappings 
            FileColumnMappings = await _context.FileColumnMapping
                .Where(f => f.TaskId == id)
                .Where(f => f.DeletedIndicator == false)
                .Include(f => f.FileInterimDataType)
                .ToListAsync();

            // Get file interim data type
            FileInterimDataTypes = _context.FileInterimDataType.Where(f => !f.DeletedIndicator).Select(f =>
                new SelectListItem
                {
                    Value = f.FileInterimDataTypeId.ToString(),
                    Text = f.FileInterimDataTypeName
                }).ToList();

            // Get TaskPropertyPassthroughMappings
            TaskPropertyPassthroughMappings = await _context.TaskPropertyPassthroughMapping
                .Where(f => f.TaskId == id)
                .Where(f => f.DeletedIndicator == false)
                .Include(f => f.Task)
                .ToListAsync();

            // Get Tasks
            Tasks = _context.Task.Include(t => t.System).Where(t => !t.DeletedIndicator && t.TaskName != Task.TaskName).Select(t =>
                new SelectListItem
                {
                    Value = t.TaskId.ToString(),
                    Text = t.System.SystemName + "." + t.TaskName
                }).ToList();

            return Page();
        }

        [BindProperty]
        public List<TaskPropertyTypeOption> TaskPropertyTypeOptions { get; set; }

        public PartialViewResult OnGetAddTaskPropertyPartial(string rowObjectId)
        {
            return Partial("TaskProperties/AddTaskPropertyPartial", rowObjectId);
        }

        // To protect from overposting attacks, please enable the specific properties you want to bind to, for
        // more details see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync()
        {
            if (!await _authorizationService.CanAccessSystem(Task.SystemId))
            {
                return Forbid();
            }
            
            if (!ModelState.IsValid) return Page();
            
            if (Task.EtlconnectionId == 0)
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

            _context.Attach(Task).State = EntityState.Modified;
            // Process file column mappings
            var existingFileColumnMappings = await _context.FileColumnMapping.Where(f => f.TaskId == Task.TaskId).ToListAsync(); 
            foreach (var fileColumnMapping in FileColumnMappings)
            {
                // Get existing file column mapping if exists 
                var existingFileColumnMapping = (from f in existingFileColumnMappings where f.FileColumnMappingId == fileColumnMapping.FileColumnMappingId select f).FirstOrDefault();
                
                if (existingFileColumnMapping == null)
                {
                    if (!string.IsNullOrWhiteSpace(fileColumnMapping.SourceColumnName) || !string.IsNullOrWhiteSpace(fileColumnMapping.TargetColumnName))
                    {
                        // this is a new item 
                        existingFileColumnMapping = new FileColumnMapping();
                        existingFileColumnMapping.TaskId = fileColumnMapping.TaskId;
                        existingFileColumnMapping.SourceColumnName = fileColumnMapping.SourceColumnName;
                        existingFileColumnMapping.TargetColumnName = fileColumnMapping.TargetColumnName;
                        existingFileColumnMapping.FileInterimDataTypeId = fileColumnMapping.FileInterimDataTypeId;
                        existingFileColumnMapping.DataLength = fileColumnMapping.DataLength;
                        existingFileColumnMapping.DeletedIndicator = fileColumnMapping.DeletedIndicator;
                        _context.FileColumnMapping.Add(existingFileColumnMapping);
                    }
                }
                else
                {
                    // If deleted, then delete
                    if (fileColumnMapping.DeletedIndicator == true)
                    {
                        existingFileColumnMapping.DeletedIndicator = true;
                    }
                    // Else, modified
                    else
                    {
                        existingFileColumnMapping.TaskId = fileColumnMapping.TaskId;
                        existingFileColumnMapping.SourceColumnName = fileColumnMapping.SourceColumnName;
                        existingFileColumnMapping.TargetColumnName = fileColumnMapping.TargetColumnName;
                        existingFileColumnMapping.FileInterimDataTypeId = fileColumnMapping.FileInterimDataTypeId;
                        existingFileColumnMapping.DataLength = fileColumnMapping.DataLength;
                    }

                    // Commit change
                    _context.Entry(existingFileColumnMapping).State = EntityState.Modified;
                }
            }

            // Process task property passthrough mapping
            var existingTaskPropertyPassthroughMappings = await _context.TaskPropertyPassthroughMapping.Where(t => t.TaskId == Task.TaskId).ToListAsync();
            foreach (var taskPropertyPassthroughMapping in TaskPropertyPassthroughMappings)
            {
                // Get existing file column mapping if exists 
                var existingTaskPropertyPassthroughMapping = (from t in existingTaskPropertyPassthroughMappings where t.TaskPropertyPassthroughMappingId == taskPropertyPassthroughMapping.TaskPropertyPassthroughMappingId select t).FirstOrDefault();

                if (existingTaskPropertyPassthroughMapping == null)
                {
                    
                    // this is a new item 
                    existingTaskPropertyPassthroughMapping = new TaskPropertyPassthroughMapping();
                    existingTaskPropertyPassthroughMapping.TaskId = taskPropertyPassthroughMapping.TaskId;
                    existingTaskPropertyPassthroughMapping.TaskPassthroughId = taskPropertyPassthroughMapping.TaskPassthroughId;
                    existingTaskPropertyPassthroughMapping.DeletedIndicator = taskPropertyPassthroughMapping.DeletedIndicator;
                    _context.TaskPropertyPassthroughMapping.Add(existingTaskPropertyPassthroughMapping);
                    
                }
                else
                {
                    // If deleted, then delete
                    if (taskPropertyPassthroughMapping.DeletedIndicator == true)
                    {
                        existingTaskPropertyPassthroughMapping.DeletedIndicator = true;
                    }
                    // Else, modified
                    else
                    {
                        existingTaskPropertyPassthroughMapping.TaskId = taskPropertyPassthroughMapping.TaskId;
                        existingTaskPropertyPassthroughMapping.TaskPassthroughId = taskPropertyPassthroughMapping.TaskPassthroughId;
                    }

                    // Commit change
                    _context.Entry(existingTaskPropertyPassthroughMapping).State = EntityState.Modified;
                }
            }

            // Process task properties
            var existingProps = await _context.TaskProperty.Where(p => p.TaskId == Task.TaskId).ToListAsync();
            foreach (var property in CurrentTaskProperties)
            {
                var taskPropertyType = _context.TaskPropertyType.Find(property.TaskPropertyTypeId);
                // Special case: We prepend this value with a computed value to prevent users
                // from affecting other systems
                if (taskPropertyType.TaskPropertyTypeName == "Target File Path" && !string.IsNullOrWhiteSpace(property.TaskPropertyValue))
                {
                    var system = _context.System.Find(Task.SystemId);
                    property.TaskPropertyValue = system.TargetPathPrefix + property.TaskPropertyValue;
                }

                var existingProp = (from p in existingProps where p.TaskPropertyTypeId == property.TaskPropertyTypeId select p).FirstOrDefault();
                if (property.TaskPropertyId == -1)
                {
                    if (!string.IsNullOrWhiteSpace(property.TaskPropertyValue))
                    {
                        // New, but only if there isn't a soft deleted sysprop
                        if (existingProp == null)
                        {
                            // new!
                            existingProp = new TaskProperty();
                            existingProp.TaskPropertyTypeId = property.TaskPropertyTypeId;
                            existingProp.TaskPropertyValue = property.TaskPropertyValue;
                            existingProp.TaskId = Task.TaskId;
                            
                            _context.TaskProperty.Add(existingProp);
                        }
                        else
                        {
                            // undelete!
                            existingProp.DeletedIndicator = false;
                            existingProp.TaskPropertyValue = property.TaskPropertyValue;
                            _context.Entry(existingProp).State = EntityState.Modified;
                        }
                    }
                }
                else
                {
                    existingProp.TaskId = Task.TaskId;
                    if (string.IsNullOrWhiteSpace(property.TaskPropertyValue))
                    {
                        existingProp.DeletedIndicator = true;
                    }
                    else
                    {
                        existingProp.TaskPropertyValue = property.TaskPropertyValue;
                    }
                    _context.Entry(existingProp).State = EntityState.Modified;
                }
            }

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!TaskExists(Task.TaskId))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return Redirect($"./Index?systemid={Task.SystemId}");
        }
        
        public JsonResult OnGetFileInterimList()
        {
            var jsonData = _context.FileInterimDataType.Where(f => f.DeletedIndicator == false).ToList();
            
            return new JsonResult(jsonData);
        }

        private bool TaskExists(int id)
        {
            return _context.Task.Any(e => e.TaskId == id);
        }
    }
}
