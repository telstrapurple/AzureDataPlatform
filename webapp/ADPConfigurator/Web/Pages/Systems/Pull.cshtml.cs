using System.ComponentModel.DataAnnotations;
using System.Net.Http;
using System.Threading.Tasks;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Newtonsoft.Json;
using System;
using ADPConfigurator.Domain;
using ADPConfigurator.Domain.Repositories;

namespace ADPConfigurator.Web.Pages.Systems
{
    public class PullModel : PageModel
    {
        private ConfiguratorApiClient _apiClient;
        private ADS_ConfigContext _context;
        private SystemRepository _systemRepository;

        public PullModel(ConfiguratorApiClient apiClient, ADS_ConfigContext context, SystemRepository systemRepository)
        {
            _apiClient = apiClient;
            _context = context;
            _systemRepository = systemRepository;
        }

        [BindProperty]
        [Required]
        public string SystemName { get; set; }

        [BindProperty]
        public bool SubmitChanges { get; set; }

        public Domain.Models.System PulledSystem { get; set; }

        public Domain.Models.System ExistingSystem { get; set; }

        public string Diff { get; set; }

        public string Error { get; set; }

        public void OnGet(string SystemName)
        {
            this.SystemName = SystemName;
        }

        public async Task<IActionResult> OnPost()
        {
            if (!ModelState.IsValid) return Page();

            try
            {
                PulledSystem = await _apiClient.GetSystem(SystemName);
            }
            catch (HttpRequestException e)
            {
                Error = e.Message;
                ModelState.AddModelError(
                    "SystemName", e.Message.Contains("404")
                    ? "No system found with that name"
                    : "A system error has occurred. Please contact support."
                );
                return Page();
            }

            ExistingSystem = ExistingSystem = await _systemRepository.GetFullyTraversedSystem(PulledSystem.SystemName);


            if (SubmitChanges)
            {
                try
                {
                    if (ExistingSystem != null)
                    {
                        ExistingSystem.Pull(PulledSystem, _context);
                    }
                    else
                    {
                        var newSystem = Domain.Models.System.PullNew(PulledSystem, _context);
                        _context.Add(newSystem);
                    }
                    await _context.SaveChangesAsync();
                    return RedirectToPage("./Index");
                }
                catch (Exception e)
                {
                    ModelState.AddModelError("SystemName", e.Message);
                    return Page();
                }
            }

            if (ExistingSystem != null && PulledSystem != null)
            {
                var diff = new EntityDiff();
                ExistingSystem.Diff(diff, PulledSystem);

                Diff = diff.ToString();
                if (string.IsNullOrEmpty(Diff)) {
                    ModelState.AddModelError("SystemName", "There are no changes to pull");
                }
            }

            return Page();
        }
    }
}
