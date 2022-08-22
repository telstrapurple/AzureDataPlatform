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
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Web.Pages.MaintenanceData.Connections
{
    [Authorize(Policy = AuthorisationPolicies.IsAdmin)]
    public class CreateModel : PageModel
    {
        private readonly ADS_ConfigContext _context;

        public CreateModel(ADS_ConfigContext context, SignedInUserProvider signedInUserProvider)
        {
            _context = context;
        }
        [BindProperty]
        public List<ConnectionProperty> CurrentConnectionProperties { get; set; }
        [BindProperty]
        public Connection Connection { get; set; }
        [BindProperty]
        public List<ConnectionPropertyTypeOption> ConnectionPropertyTypeOptions { get; set; }
        public List<string> SystemCodeOptions { get; set; }
        [BindProperty]
        public List<ConnectionType> ConnectionType { get; set; }
        [BindProperty]
        public List<ConnectionTypeAuthenticationTypeMapping> ConnectionTypeAuthenticationTypeMapping { get; set; }

        private async System.Threading.Tasks.Task _prepare()
        {
            CurrentConnectionProperties = new List<ConnectionProperty>();
            ConnectionPropertyTypeOptions = _context.ConnectionPropertyTypeOption.Where(t => !t.DeletedIndicator).ToList();
            ConnectionTypeAuthenticationTypeMapping = new List<ConnectionTypeAuthenticationTypeMapping>();
            SystemCodeOptions = _context.System.Select(x => x.SystemCode).Distinct().ToList();
            SystemCodeOptions.Insert(0, "");
            ConnectionTypeAuthenticationTypeMapping = _context.ConnectionTypeAuthenticationTypeMapping
                .Include(c => c.ConnectionType)
                .Include(c => c.AuthenticationType)
                .Where(c => !c.DeletedIndicator && !c.ConnectionType.DeletedIndicator && !c.AuthenticationType.DeletedIndicator)
                .ToList();

            ViewData["ConnectionTypeId"] = new SelectList(_context.ConnectionType, "ConnectionTypeId", "ConnectionTypeName");
            ViewData["ConnectionTypeConnectionPropertyTypeMapping"] = JsonSerializer.Serialize(_context.ConnectionTypeConnectionPropertyTypeMapping.Include(c => c.ConnectionTypeAuthenticationTypeMapping).Where(c => !c.DeletedIndicator).Where(c => !c.ConnectionTypeAuthenticationTypeMapping.DeletedIndicator).Select(c => new { connectionTypeAuthenticationTypeMappingId = c.ConnectionTypeAuthenticationTypeMappingId, connectionPropertyTypeId = c.ConnectionPropertyTypeId, authenticationTypeId = c.ConnectionTypeAuthenticationTypeMapping.AuthenticationTypeId, connectionTypeId = c.ConnectionTypeAuthenticationTypeMapping.ConnectionTypeId }).ToList()).ToString();
            ViewData["AuthenticationTypeList"] = new SelectList(_context.AuthenticationType, "AuthenticationTypeId", "AuthenticationTypeName");
            ViewData["ConnectionTypeAuthenticationTypeMapping"] = JsonSerializer.Serialize(_context.ConnectionTypeAuthenticationTypeMapping.Include(c => c.ConnectionType).Include(c => c.AuthenticationType).Where(c => !c.DeletedIndicator).Where(c => !c.ConnectionType.DeletedIndicator).Where(c => !c.AuthenticationType.DeletedIndicator).Select(c => new { authenticationTypeId = c.AuthenticationTypeId, authenticationTypeName = c.AuthenticationType.AuthenticationTypeName, connectionTypeId = c.ConnectionTypeId }).ToList()).ToString();
            ViewData["SelectedAuthenticationTypeId"] = await _context.Connection.Where(c => !c.DeletedIndicator).Select(c => c.AuthenticationTypeId).FirstOrDefaultAsync();

            // Only show non-deleted
            var allTypes = await _context.ConnectionPropertyType
                .Include(t => t.ConnectionPropertyTypeValidation)
                .OrderBy(c => c.ConnectionPropertyTypeId)
                .ToListAsync();

            foreach (var type in allTypes)
            {
                if (CurrentConnectionProperties.Where(x => x.ConnectionPropertyTypeId == type.ConnectionPropertyTypeId).Any())
                {
                    continue;
                }
                var matchingConnectionProp = new ConnectionProperty();
                matchingConnectionProp.ConnectionPropertyTypeId = type.ConnectionPropertyTypeId;
                matchingConnectionProp.ConnectionPropertyType = type;
                matchingConnectionProp.ConnectionPropertyType.ConnectionPropertyTypeValidationId = type.ConnectionPropertyTypeValidationId;
                matchingConnectionProp.ConnectionPropertyType.ConnectionPropertyTypeValidation.ConnectionPropertyTypeValidationName = type.ConnectionPropertyTypeValidation.ConnectionPropertyTypeValidationName;
                CurrentConnectionProperties.Add(matchingConnectionProp);
            }
        }

        public async Task<IActionResult> OnGetAsync()
        {
            Connection = new Connection();
            Connection.SystemCode = string.IsNullOrEmpty(Connection.SystemCode) ? "" : Connection.SystemCode;
            await _prepare();

            return Page();
        }
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for
        // more details see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync()
        {
            if (Connection.Generic == false && string.IsNullOrEmpty(Connection.SystemCode))
            {
                Connection.SystemCode = "";
                ModelState.AddModelError("Connection.SystemCode", "You must select a system code when the connection is not marked as generic");
            }
            if (Connection.Generic == true && !string.IsNullOrEmpty(Connection.SystemCode))
            {
                Connection.SystemCode = "";
                ModelState.AddModelError("Connection.SystemCode", "A connection cannot be both generic, and restricted to a system code");
            }
            if (!ModelState.IsValid)
            {
                await _prepare();
                return Page();
            }

            Connection.SystemCode = string.IsNullOrEmpty(Connection.SystemCode) ? null : Connection.SystemCode;
            _context.Connection.Add(Connection);
            // Process task properties 
            foreach (var property in CurrentConnectionProperties)
            {
                if (!string.IsNullOrWhiteSpace(property.ConnectionPropertyValue))
                {
                    property.ConnectionId = Connection.ConnectionId;
                    Connection.ConnectionProperty.Add(property);
                }
            }

            _context.Connection.Add(Connection);
            await _context.SaveChangesAsync();

            return RedirectToPage("./Index");
        }
    }
}
