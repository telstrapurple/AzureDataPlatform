using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Identity.Web;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Api.Infrastructure.AzureSql;
using ADPConfigurator.Common.Infrastructure.AzureSql;
using ADPConfigurator.Domain.Repositories;

namespace ADPConfigurator.Api
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers().AddNewtonsoftJson();
            services.AddSingleton<IAzureSqlTokenProvider, AzureIdentityAzureSqlTokenProvider>();
            services.AddScoped<AzureAdAuthenticationDbConnectionInterceptor>();

            services
                .AddDbContext<ADS_ConfigContext>((provider, options) =>
                {
                    options.UseSqlServer(Configuration["ApplicationConfig:ConnectionString"]);
                    options.AddInterceptors(provider.GetRequiredService<AzureAdAuthenticationDbConnectionInterceptor>());
                });

            services.AddScoped<SystemRepository>();

            // Require that users authenticate to our AAD app registration
            services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddMicrosoftIdentityWebApi(Configuration.GetSection("AzureAd"));

            services.AddAuthorization(options =>
            {
                options.DefaultPolicy = new AuthorizationPolicyBuilder(JwtBearerDefaults.AuthenticationScheme, "Bearer")
                    .RequireAuthenticatedUser()
                    .RequireScope(Configuration["AzureAD:Scopes"])
                    .Build();
            });
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseHttpsRedirection();

            app.UseRouting();

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers().RequireAuthorization();
            });
        }
    }
}
