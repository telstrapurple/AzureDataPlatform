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
    public class EditModel : PageModel
    {
        private readonly ADS_ConfigContext _context;

        public EditModel(ADS_ConfigContext context, SignedInUserProvider signedInUserProvider)
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
        public List<ConnectionTypeAuthenticationTypeMapping> ConnectionTypeAuthenticationTypeMapping { get; set; }

        private async System.Threading.Tasks.Task _prepare()
        {
            Connection.SystemCode = string.IsNullOrEmpty(Connection.SystemCode) ? "" : Connection.SystemCode;
            CurrentConnectionProperties = new List<ConnectionProperty>();
            ConnectionPropertyTypeOptions = _context.ConnectionPropertyTypeOption.Where(t => !t.DeletedIndicator).ToList();
            SystemCodeOptions = _context.System.Select(x => x.SystemCode).Distinct().ToList();
            SystemCodeOptions.Insert(0, null);
            ConnectionTypeAuthenticationTypeMapping = new List<ConnectionTypeAuthenticationTypeMapping>();
            ConnectionTypeAuthenticationTypeMapping = _context.ConnectionTypeAuthenticationTypeMapping
                .Include(c => c.ConnectionType)
                .Include(c => c.AuthenticationType)
                .Where(c => !c.DeletedIndicator && !c.ConnectionType.DeletedIndicator && !c.AuthenticationType.DeletedIndicator)
                .ToList();

            // Only show non-deleted
            var allTypes = await _context.ConnectionPropertyType
                .Include(t => t.ConnectionProperty)
                .Include(t => t.ConnectionPropertyTypeValidation)
                .OrderBy(t => t.ConnectionPropertyTypeName)
                .ToListAsync();

            if (CurrentConnectionProperties == null)
            {
                CurrentConnectionProperties = new List<ConnectionProperty>();
            }
            foreach (var type in allTypes)
            {
                if (CurrentConnectionProperties.Where(x => x.ConnectionPropertyTypeId == type.ConnectionPropertyTypeId).Any())
                {
                    continue;
                }
                var matchingConnectionProp = (from p in Connection.ConnectionProperty where p.ConnectionPropertyTypeId == type.ConnectionPropertyTypeId select p).SingleOrDefault();
                // Bit complicated. If it's been cleared/deleted previously then treat it as new, however when posting if a value is set then 'un-delete' the existing record and overwrite the value
                if (matchingConnectionProp == null || matchingConnectionProp.DeletedIndicator)
                {
                    matchingConnectionProp = new ConnectionProperty();
                    // -1 id properties are for insertion (if set)
                    matchingConnectionProp.ConnectionPropertyId = -1;
                    matchingConnectionProp.ConnectionPropertyTypeId = type.ConnectionPropertyTypeId;
                }
                matchingConnectionProp.ConnectionPropertyType = type;
                matchingConnectionProp.ConnectionPropertyType.ConnectionPropertyTypeValidationId = type.ConnectionPropertyTypeValidationId;
                matchingConnectionProp.ConnectionPropertyType.ConnectionPropertyTypeValidation.ConnectionPropertyTypeValidationName = type.ConnectionPropertyTypeValidation.ConnectionPropertyTypeValidationName;

                CurrentConnectionProperties.Add(matchingConnectionProp);
            }

            ViewData["ConnectionTypeId"] = new SelectList(_context.ConnectionType, "ConnectionTypeId", "ConnectionTypeName");
            ViewData["ConnectionTypeConnectionPropertyTypeMapping"] = JsonSerializer.Serialize(_context.ConnectionTypeConnectionPropertyTypeMapping.Include(c => c.ConnectionTypeAuthenticationTypeMapping).Where(c => !c.DeletedIndicator).Where(c => !c.ConnectionTypeAuthenticationTypeMapping.DeletedIndicator).Select(c => new { connectionTypeAuthenticationTypeMappingId = c.ConnectionTypeAuthenticationTypeMappingId, connectionPropertyTypeId = c.ConnectionPropertyTypeId, authenticationTypeId = c.ConnectionTypeAuthenticationTypeMapping.AuthenticationTypeId, connectionTypeId = c.ConnectionTypeAuthenticationTypeMapping.ConnectionTypeId }).ToList()).ToString();
            ViewData["AuthenticationTypeList"] = new SelectList(_context.AuthenticationType, "AuthenticationTypeId", "AuthenticationTypeName");
            ViewData["ConnectionTypeAuthenticationTypeMapping"] = JsonSerializer.Serialize(_context.ConnectionTypeAuthenticationTypeMapping.Include(c => c.ConnectionType).Include(c => c.AuthenticationType).Where(c => !c.DeletedIndicator).Where(c => !c.ConnectionType.DeletedIndicator).Where(c => !c.AuthenticationType.DeletedIndicator).Select(c => new { authenticationTypeId = c.AuthenticationTypeId, authenticationTypeName = c.AuthenticationType.AuthenticationTypeName, connectionTypeId = c.ConnectionTypeId }).ToList()).ToString();
            ViewData["SelectedAuthenticationTypeId"] = await _context.Connection.Where(c => c.ConnectionId == Connection.ConnectionId).Select(c => c.AuthenticationTypeId).FirstOrDefaultAsync();
        }

        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            Connection = await _context.Connection
                .Include(c => c.ConnectionType).FirstOrDefaultAsync(m => m.ConnectionId == id);
            if (Connection == null)
            {
                return NotFound();
            }
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
            _context.Attach(Connection).State = EntityState.Modified;
            
            // Process system properties
            var existingProps = await _context.ConnectionProperty.Where(p => p.ConnectionId == Connection.ConnectionId).ToListAsync();
            foreach (var property in CurrentConnectionProperties)
            {
                var existingProp = (from p in existingProps where p.ConnectionPropertyTypeId == property.ConnectionPropertyTypeId select p).FirstOrDefault();
                if (property.ConnectionPropertyId == -1)
                {
                    if (!string.IsNullOrWhiteSpace(property.ConnectionPropertyValue))
                    {
                        // New, but only if there isn't a soft deleted sysprop
                        if (existingProp == null)
                        {
                            // new!
                            existingProp = new ConnectionProperty();
                            existingProp.ConnectionPropertyTypeId = property.ConnectionPropertyTypeId;
                            existingProp.ConnectionPropertyValue = property.ConnectionPropertyValue;
                            existingProp.ConnectionId = Connection.ConnectionId;

                            _context.ConnectionProperty.Add(existingProp);
                        }
                        else
                        {
                            // undelete!
                            existingProp.DeletedIndicator = false;
                            existingProp.ConnectionPropertyValue = property.ConnectionPropertyValue;
                            _context.Entry(existingProp).State = EntityState.Modified;
                        }
                    }
                }
                else
                {
                    existingProp.ConnectionId = Connection.ConnectionId;
                    if (string.IsNullOrWhiteSpace(property.ConnectionPropertyValue))
                    {
                        existingProp.DeletedIndicator = true;
                    }
                    else
                    {
                        existingProp.ConnectionPropertyValue = property.ConnectionPropertyValue;
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
                if (!ConnectionExists(Connection.ConnectionId))
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

        private bool ConnectionExists(int id)
        {
            return _context.Connection.Any(e => e.ConnectionId == id);
        }
    }
}
