using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Authorisation;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace ADPConfigurator.Web.Pages.Systems
{
    [Authorize(Policy = AuthorisationPolicies.IsAdmin)]
    public class CreateModel : PageModel
    {
        private readonly ADS_ConfigContext _context;
        private readonly IConfiguration _configuration;
        public readonly SignedInUserProvider SignedInUserProvider;

        public CreateModel(ADS_ConfigContext context, SignedInUserProvider signedInUserProvider, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
            SignedInUserProvider = signedInUserProvider;
        }
        [BindProperty]
        public ADPConfigurator.Domain.Models.System System { get; set; }
        [BindProperty]
        public List<SystemProperty> CurrentSystemProperties { get; set; }
        [BindProperty]
        public List<SystemDependency> SystemDependencies { get; set; }
        [BindProperty]
        public List<SystemPropertyTypeOption> SystemPropertyTypeOptions { get; set; }
        [BindProperty]
        public List<string> AvailableSystemCodes { get; set; }

        public async Task<IActionResult> OnGetAsync()
        {
            System = new ADPConfigurator.Domain.Models.System();
            // Only show non-deleted
            SystemPropertyTypeOptions = _context.SystemPropertyTypeOption.Where(t => !t.DeletedIndicator).ToList();
            var allTypes = await _context.SystemPropertyType
                .Include(t => t.SystemPropertyTypeValidation)
                .OrderBy(t => t.SystemPropertyTypeName)
                .ToListAsync();
            CurrentSystemProperties = new List<SystemProperty>();
            // ACL Permissions is a unique case - we will compute this value
            foreach (var type in allTypes.Where(x => x.SystemPropertyTypeName != "ACL Permissions"))
            {
                var newSysProp = new SystemProperty();
                newSysProp.SystemPropertyTypeId = type.SystemPropertyTypeId;
                newSysProp.SystemPropertyType = type;
                newSysProp.SystemPropertyType.SystemPropertyTypeValidationId = type.SystemPropertyTypeValidationId;
                newSysProp.SystemPropertyType.SystemPropertyTypeValidation.SystemPropertyTypeValidationName = type.SystemPropertyTypeValidation.SystemPropertyTypeValidationName;
                CurrentSystemProperties.Add(newSysProp);
            }
            ViewData["Systems"] = JsonSerializer.Serialize(_context.System.Where(s => !s.DeletedIndicator && s.SystemId != System.SystemId).Select(s => new { id = s.SystemId, name = s.SystemName }).ToList()).ToString();
            try
            {
                ViewData["SystemDependencyIndex"] = _context.SystemDependency.Max(s => s.SystemDependencyId);
            }
            catch
            {
                ViewData["SystemDependencyIndex"] = 0;
            }
            if (!SignedInUserProvider.IsGlobalAdmin)
            {
                AvailableSystemCodes = _context.System.Select(x => x.SystemCode).Distinct().ToList();
            }
            return Page();
        }

        // To protect from overposting attacks, please enable the specific properties you want to bind to, for
        // more details see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync() // string systemName
        {
            var systemQuery = await _context.System
                    .Where(s => s.SystemName == System.SystemName)
                    .ToListAsync();

            var allTypes = await _context.SystemPropertyType
                                .Include(t => t.SystemPropertyTypeValidation)
                                .OrderBy(t => t.SystemPropertyTypeName)
                                .ToListAsync();

            if (System.LocalAdminGroup == null)
            {
                ModelState.AddModelError("System.LocalAdminGroup", "This field is required");
            }
            if (System.MemberGroup == null)
            {
                ModelState.AddModelError("System.MemberGroup", "This field is required");
            }

            if (systemQuery.Count > 0)
            {
                ModelState.AddModelError("System.SystemName", "System name " + systemQuery.First().SystemName + " already in use.");
            }

            if (!ModelState.IsValid)
            {
                // ACL Permissions is a unique case - we will compute this value
                foreach (var type in allTypes.Where(x => x.SystemPropertyTypeName != "ACL Permissions"))
                {
                    var sysProp = (from p in CurrentSystemProperties where p.SystemPropertyTypeId == type.SystemPropertyTypeId select p).Single();
                    sysProp.SystemPropertyType = type;
                }
                if (!SignedInUserProvider.IsGlobalAdmin)
                {
                    AvailableSystemCodes = _context.System.Select(x => x.SystemCode).Distinct().ToList();
                }

                return Page();
            }

            if (systemQuery.Count == 0)
            {
                _context.System.Add(System);
                // Process task properties
                foreach (var property in CurrentSystemProperties)
                {
                    if (!string.IsNullOrWhiteSpace(property.SystemPropertyValue))
                    {
                        property.SystemId = System.SystemId;
                        System.SystemProperty.Add(property);
                    }
                }
                foreach (var systemDependency in SystemDependencies)
                {
                    // this is a new item 
                    var newSystemDependency = new SystemDependency();
                    newSystemDependency.SystemId = System.SystemId;
                    newSystemDependency.DependencyId = systemDependency.DependencyId;
                    newSystemDependency.DeletedIndicator = systemDependency.DeletedIndicator;
                    System.SystemDependencySystem.Add(newSystemDependency);
                }
                if (!SignedInUserProvider.IsGlobalAdmin)
                {
                    var sameCodeSystem = _context.System.Where(x => x.SystemCode == System.SystemCode).FirstOrDefault();
                    System.LocalAdminGroup = sameCodeSystem.LocalAdminGroup;
                    System.MemberGroup = sameCodeSystem.MemberGroup;
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

                var aclPermissionProperty = allTypes.Where(x => x.SystemPropertyTypeName == "ACL Permissions").FirstOrDefault();
                var newSysProp = new SystemProperty();
                newSysProp.SystemPropertyTypeId = aclPermissionProperty.SystemPropertyTypeId;
                newSysProp.SystemPropertyType = aclPermissionProperty;
                newSysProp.SystemPropertyType.SystemPropertyTypeValidationId = aclPermissionProperty.SystemPropertyTypeValidationId;
                newSysProp.SystemPropertyType.SystemPropertyTypeValidation.SystemPropertyTypeValidationName = aclPermissionProperty.SystemPropertyTypeValidation.SystemPropertyTypeValidationName;
                newSysProp.SystemPropertyValue = JsonSerializer.Serialize(aclPermissions);
                newSysProp.SystemId = System.SystemId;
                System.SystemProperty.Add(newSysProp);

                await _context.SaveChangesAsync();
                return RedirectToPage("./Index");
            }

            _context.System.Add(System);
            // Process task properties
            foreach (var property in CurrentSystemProperties)
            {
                if (!string.IsNullOrWhiteSpace(property.SystemPropertyValue))
                {
                    property.SystemId = System.SystemId;
                    System.SystemProperty.Add(property);
                }
            }
            foreach (var systemDependency in SystemDependencies)
            {
                // this is a new item 
                var newSystemDependency = new SystemDependency();
                newSystemDependency.SystemId = System.SystemId;
                newSystemDependency.DependencyId = systemDependency.DependencyId;
                newSystemDependency.DeletedIndicator = systemDependency.DeletedIndicator;
                System.SystemDependencySystem.Add(newSystemDependency);
            }
            if (!SignedInUserProvider.IsGlobalAdmin)
            {
                var sameCodeSystem = _context.System.Where(x => x.SystemCode == System.SystemCode).FirstOrDefault();
                System.LocalAdminGroup = sameCodeSystem.LocalAdminGroup;
                System.MemberGroup = sameCodeSystem.MemberGroup;
            }
            await _context.SaveChangesAsync();
            return RedirectToPage("./Index");
        }
    }
}
