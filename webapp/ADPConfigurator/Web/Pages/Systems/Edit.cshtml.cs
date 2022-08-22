using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Extensions;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace ADPConfigurator.Web.Pages.Systems
{
    public class EditModel : PageModel
    {
        private readonly ADS_ConfigContext _context;
        private readonly IAuthorizationService _authorizationService;
        private readonly IConfiguration _configuration;

        [BindProperty]
        public ADPConfigurator.Domain.Models.System System { get; set; }
        [BindProperty]
        public List<SelectListItem> Systems { get; set; }
        [BindProperty]
        public List<SystemProperty> CurrentSystemProperties { get; set; }
        [BindProperty]
        public List<SystemDependency> SystemDependencies { get; set; }
        [BindProperty]
        public List<SystemPropertyTypeOption> SystemPropertyTypeOptions { get; set; }
        public readonly SignedInUserProvider SignedInUserProvider;

        public EditModel(ADS_ConfigContext context, IAuthorizationService authorizationService, SignedInUserProvider signedInUserProvider, IConfiguration configuration)
        {
            _context = context;
            _authorizationService = authorizationService;
            _configuration = configuration;
            SignedInUserProvider = signedInUserProvider;
        }

        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null) return NotFound();

            if (!await _authorizationService.CanAccessSystem((int)id))
            {
                return Forbid();
            }

            System = await _context.System
                .Include(m => m.SystemProperty)
                .FirstOrDefaultAsync(m => m.SystemId == id);

            if (System == null) return NotFound();

            // Only show non-deleted
            SystemPropertyTypeOptions = _context.SystemPropertyTypeOption.Where(t => !t.DeletedIndicator).ToList();

            var allTypes = await _context.SystemPropertyType
                .Include(t => t.SystemPropertyTypeValidation)
                .OrderBy(t => t.SystemPropertyTypeName)
                .ToListAsync();
            CurrentSystemProperties = new List<SystemProperty>();
            foreach (var type in allTypes.Where(x => x.SystemPropertyTypeName != "ACL Permissions"))
            {
                var matchingSysProp = (from p in System.SystemProperty where p.SystemPropertyTypeId == type.SystemPropertyTypeId select p).SingleOrDefault();
                // Bit complicated. If it's been cleared/deleted previously then treat it as new, however when posting if a value is set then 'un-delete' the existing record and overwrite the value
                if (matchingSysProp == null || matchingSysProp.DeletedIndicator)
                {
                    matchingSysProp = new SystemProperty();
                    // -1 id properties are for insertion (if set)
                    matchingSysProp.SystemPropertyId = -1;
                    matchingSysProp.SystemPropertyTypeId = type.SystemPropertyTypeId;
                }
                matchingSysProp.SystemPropertyType = type;
                matchingSysProp.SystemPropertyType.SystemPropertyTypeValidationId = type.SystemPropertyTypeValidationId;
                matchingSysProp.SystemPropertyType.SystemPropertyTypeValidation.SystemPropertyTypeValidationName = type.SystemPropertyTypeValidation.SystemPropertyTypeValidationName;

                CurrentSystemProperties.Add(matchingSysProp);
            }

            // Get system dependencies
            SystemDependencies = await _context.SystemDependency
                .Where(s => s.SystemId == id)
                .Where(s => s.DeletedIndicator == false)
                .Where(s => s.EnabledIndicator == true)
                .ToListAsync();

            // Get systems
            Systems = _context.System
                .Where(s => s.DeletedIndicator == false)
                .Where(s => s.EnabledIndicator == true)
                .Select(s =>
                    new SelectListItem
                    {
                        Value = s.SystemId.ToString(),
                        Text = s.SystemName
                    }).ToList();
            ViewData["SystemList"] = new SelectList(_context.System.Where(s => !s.DeletedIndicator && s.SystemId != System.SystemId), "SystemId", "SystemName");
            ViewData["Systems"] = JsonSerializer.Serialize(_context.System.Where(s => !s.DeletedIndicator && s.SystemId != System.SystemId).Select(s => new { id = s.SystemId, name = s.SystemName }).ToList()).ToString();
            try
            {
                ViewData["SystemDependencyIndex"] = _context.SystemDependency.Max(s => s.SystemDependencyId);
            }
            catch
            {
                ViewData["SystemDependencyIndex"] = 0;
            }
            return Page();
        }

        // To protect from overposting attacks, please enable the specific properties you want to bind to, for
        // more details see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync()
        {
            if (!await _authorizationService.CanAccessSystem(System.SystemId))
            {
                return Forbid();
            }

            if (!ModelState.IsValid) return Page();

            var systemQuery = await _context.System
                    .Where(s => s.SystemName == System.SystemName && s.SystemId != System.SystemId)
                    .ToListAsync();

            var allTypes = await _context.SystemPropertyType
                .OrderBy(t => t.SystemPropertyTypeName)
                .Include(t => t.SystemPropertyTypeValidation)
                .ToListAsync();

            if (systemQuery.Count != 0)
            {
                foreach (var type in allTypes.Where(x => x.SystemPropertyTypeName != "ACL Permissions"))
                {
                    var sysProp = (from p in CurrentSystemProperties where p.SystemPropertyTypeId == type.SystemPropertyTypeId select p).Single();
                    sysProp.SystemPropertyType = type;
                }
                ModelState.AddModelError("System.SystemName", "System name " + systemQuery.First().SystemName + " already in use.");

                return Page();
            }

            _context.Attach(System).State = EntityState.Modified;


            // Process system dependency
            var existingSystemDependencies = await _context.SystemDependency.Where(s => s.SystemId == System.SystemId).ToListAsync();
            foreach (var systemDependency in SystemDependencies)
            {
                // Get existing system dependency if exists 
                var existingSystemDependency = (from s in existingSystemDependencies where s.DependencyId == systemDependency.DependencyId select s).FirstOrDefault();

                if (existingSystemDependency == null)
                {
                    // this is a new item 
                    existingSystemDependency = new SystemDependency();
                    existingSystemDependency.SystemId = System.SystemId;
                    existingSystemDependency.DependencyId = systemDependency.DependencyId;
                    existingSystemDependency.DeletedIndicator = systemDependency.DeletedIndicator;
                    _context.SystemDependency.Add(existingSystemDependency);

                }
                else
                {
                    // If deleted, then delete
                    if (systemDependency.DeletedIndicator)
                    {
                        existingSystemDependency.DeletedIndicator = true;
                    }
                    // Else, modified
                    else
                    {
                        existingSystemDependency.SystemId = System.SystemId;
                        existingSystemDependency.DependencyId = systemDependency.DependencyId;
                        // If it was deleted, it has been undeleted
                        existingSystemDependency.DeletedIndicator = false;
                    }

                    // Commit change
                    _context.Entry(existingSystemDependency).State = EntityState.Modified;
                }
            }

            // Process system properties
            var existingProps = await _context.SystemProperty.Where(p => p.SystemId == System.SystemId).ToListAsync();
            foreach (var property in CurrentSystemProperties)
            {
                var existingProp = (from p in existingProps where p.SystemPropertyTypeId == property.SystemPropertyTypeId select p).FirstOrDefault();
                if (property.SystemPropertyId == -1)
                {
                    if (!string.IsNullOrWhiteSpace(property.SystemPropertyValue))
                    {
                        // New, but only if there isn't a soft deleted sysprop
                        if (existingProp == null)
                        {
                            // new!
                            existingProp = new SystemProperty();
                            existingProp.SystemPropertyTypeId = property.SystemPropertyTypeId;
                            existingProp.SystemPropertyValue = property.SystemPropertyValue;
                            existingProp.SystemId = System.SystemId;

                            _context.SystemProperty.Add(existingProp);
                        }
                        else
                        {
                            // undelete!
                            existingProp.DeletedIndicator = false;
                            existingProp.SystemPropertyValue = property.SystemPropertyValue;
                            _context.Entry(existingProp).State = EntityState.Modified;
                        }
                    }
                }
                else
                {
                    existingProp.SystemId = System.SystemId;
                    if (string.IsNullOrWhiteSpace(property.SystemPropertyValue))
                    {
                        existingProp.DeletedIndicator = true;
                    }
                    else
                    {
                        existingProp.SystemPropertyValue = property.SystemPropertyValue;
                    }
                    _context.Entry(existingProp).State = EntityState.Modified;
                }
            }

            var aclPermissions = new AclSpecification(
                _configuration["ApplicationConfig:EnvironmentName"],
                _configuration["ApplicationConfig:DatalakeStorageEndpoint"],
                System.SystemCode,
                _configuration["ApplicationConfig:GlobalAdminGroupId"],
                _configuration["ApplicationConfig:DatafactoryServicePrincipal"],
                _configuration["ApplicationConfig:DatabricksServicePrincipal"],
                System.ReadonlyGroup.ToString(),
                System.LocalAdminGroup.ToString(),
                System.MemberGroup.ToString()
            );

            var aclPermissionPropertyType = allTypes.Where(x => x.SystemPropertyTypeName == "ACL Permissions").FirstOrDefault();
            SystemProperty aclSysProp = _context.SystemProperty.Where(p => p.SystemId == System.SystemId && p.SystemPropertyTypeId == aclPermissionPropertyType.SystemPropertyTypeId).FirstOrDefault();
            aclSysProp ??= new SystemProperty();
            aclSysProp.SystemPropertyTypeId = aclPermissionPropertyType.SystemPropertyTypeId;
            aclSysProp.SystemPropertyType = aclPermissionPropertyType;
            aclSysProp.SystemPropertyType.SystemPropertyTypeValidationId = aclPermissionPropertyType.SystemPropertyTypeValidationId;
            aclSysProp.SystemPropertyType.SystemPropertyTypeValidation.SystemPropertyTypeValidationName = aclPermissionPropertyType.SystemPropertyTypeValidation.SystemPropertyTypeValidationName;
            aclSysProp.SystemPropertyValue = JsonSerializer.Serialize(aclPermissions);
            aclSysProp.SystemId = System.SystemId;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!SystemExists(System.SystemId))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return RedirectToPage("./Index");
        }

        private bool SystemExists(int id)
        {
            return _context.System.Any(e => e.SystemId == id);
        }
    }
}
