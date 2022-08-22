using System;
using ADPConfigurator.Common.Config;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Domain.Repositories;
using ADPConfigurator.Web.Authorisation;
using ADPConfigurator.Web.Infrastructure;
using ADPConfigurator.Web.Infrastructure.AzureSql;
using ADPConfigurator.Web.Services;
using Microsoft.AspNetCore.Authentication.AzureAD.UI;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.UI;

namespace ADPConfigurator.Web
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        private IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            var appConfig = Configuration.GetSection(nameof(ApplicationConfig)).Get<ApplicationConfig>();

            services.AddSingleton(appConfig);

            services.AddHttpContextAccessor();
            services.AddApplicationInsightsTelemetry();

            services.AddMemoryCache();
            services.AddScoped<PrincipalProvider, PrincipalProvider>();
            services.AddSingleton<IAzureSqlTokenProvider, AzureIdentityAzureSqlTokenProvider>();
            services.Decorate<IAzureSqlTokenProvider, MemoryCacheAzureSqlTokenProvider>();
            services.AddScoped<AzureAdAuthenticationDbConnectionInterceptor>();

            services.AddScoped<ConfiguratorApiClient, ConfiguratorApiClient>();
            services.AddScoped<PullSourceStateProvider, PullSourceStateProvider>();

            services
                .AddDbContext<ADS_ConfigContext>((provider, options) =>
                {
                    options.UseSqlServer(appConfig.ConnectionString);
                    options.AddInterceptors(provider.GetRequiredService<AzureAdAuthenticationDbConnectionInterceptor>());
                });

            services.AddScoped<SystemRepository>();

            services
                .AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
                .AddMicrosoftIdentityWebApp(options =>
                {
                    Configuration.Bind("AzureAd", options);
                })
                .EnableTokenAcquisitionToCallDownstreamApi(new string[] { "User.Read", Configuration["PullSource:Scopes"]})
                .AddMicrosoftGraph("https://graph.microsoft.com/v1.0", "User.Read")
                .AddDownstreamWebApi(ConfiguratorApiClient.ApiName, Configuration.GetSection("PullSource"))
                .AddInMemoryTokenCaches();

            services
                .AddMvc(options =>
                {
                    options.Filters.Add(new AuthorizeFilter());
                    options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute());
                })
                .AddRazorPagesOptions(options =>
                {
                    options.Conventions.AddPageRoute("/Systems/Index", "");
                }).AddMicrosoftIdentityUI();

            services.AddAuthorization(options =>
            {
                options.AddPolicy(AuthorisationPolicies.IsAdmin,
                    policy => policy.Requirements.Add(new IsAdminRequirement()));
                options.AddPolicy(AuthorisationPolicies.IsGlobalAdmin,
                    policy => policy.Requirements.Add(new IsGlobalAdminRequirement()));
                options.AddPolicy(AuthorisationPolicies.CanAccessSystem,
                    policy => policy.Requirements.Add(new CanAccessSystemRequirement()));
            });

            services.AddTransient<IAuthorizationHandler, IsAdminAuthorizationHandler>();
            services.AddTransient<IAuthorizationHandler, IsGlobalAdminAuthorizationHandler>();
            services.AddTransient<IAuthorizationHandler, CanAccessSystemAuthorizationHandler>();

            services
                .Configure<CookiePolicyOptions>(options =>
                {
                    // This lambda determines whether user consent for non-essential cookies is needed for a given request.
                    options.CheckConsentNeeded = context => true;
                    options.MinimumSameSitePolicy = SameSiteMode.None;
                })
                .Configure<FormOptions>(options =>
                {
                    options.ValueCountLimit = int.MaxValue;
                })
                .Configure<OpenIdConnectOptions>(AzureADDefaults.OpenIdScheme, options =>
                {
                    options.Authority += "/v2.0/";
                    options.TokenValidationParameters.ValidateIssuer = true;
                });

            services.AddScoped<SignedInUserProvider, SignedInUserProvider>();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }
            app.UseHardenedSecurityHeaders();
            app.UseHttpsRedirection();
            app.UseStaticFiles();
            app.UseCookiePolicy();
            app.UseRouting();
            app.UseAuthentication();
            app.UseContextInterceptor();
            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapRazorPages();
            });
        }
    }
}
