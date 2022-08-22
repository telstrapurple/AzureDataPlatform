using Microsoft.AspNetCore.Builder;

namespace ADPConfigurator.Web.Infrastructure
{
    public static class SecurityHeaderMiddleware
    {
        public static void UseHardenedSecurityHeaders(this IApplicationBuilder app)
        {
            // using https://github.com/andrewlock/NetEscapades.AspNetCore.SecurityHeaders
            // X - Frame: only applied to text / html responses
            // X - XSS: only applied to text / html responses
            // Referrer - Policy: only applied to text / html responses
            // Content - Security - Policy: only applied to text / html responses

            var policyCollection = new HeaderPolicyCollection()
                .AddXssProtectionBlock()
                .AddContentTypeOptionsNoSniff()
                .AddFrameOptionsDeny()
                .AddReferrerPolicyStrictOriginWhenCrossOrigin()
                .RemoveServerHeader()
                .AddContentSecurityPolicyReportOnly(builder =>
                {
                    builder.AddObjectSrc().None();
                    builder.AddFormAction().Self();
                    builder.AddDefaultSrc().Self();
                    builder.AddScriptSrc()
                        .Self()
                        // Inline <script> tags
                        .WithNonce()
                        // App Insights JS SDK
                        .From("https://az416426.vo.msecnd.net");
                    builder.AddFrameAncestors()
                        .None();
                    builder.AddFrameSource()
                        .None();
                    builder.AddStyleSrc()
                        .Self()
                        // Inline <style> tags
                        .WithNonce();

                    builder.AddConnectSrc()
                        .Self()
                        // App Insights telemetry
                        .From("https://dc.services.visualstudio.com");
                })
                .AddFeaturePolicy(builder =>
                {
                    builder.AddAccelerometer().None();
                    builder.AddAmbientLightSensor().None();
                    builder.AddAutoplay().None();
                    builder.AddCamera().None();
                    builder.AddEncryptedMedia().Self();
                    builder.AddFullscreen().All();
                    builder.AddGeolocation().None();
                    builder.AddGyroscope().None();
                    builder.AddMagnetometer().None();
                    builder.AddMicrophone().None();
                    builder.AddMidi().None();
                    builder.AddPayment().None();
                    builder.AddPictureInPicture().None();
                    builder.AddSpeaker().None();
                    builder.AddSyncXHR().None();
                    builder.AddUsb().None();
                    builder.AddVR().None();
                })
                .AddPermissionsPolicy (builder =>
                {
                    builder.AddAccelerometer().None();
                    builder.AddAmbientLightSensor().None();
                    builder.AddAutoplay().None();
                    builder.AddCamera().None();
                    builder.AddFullscreen().All();
                    builder.AddGeolocation().None();
                    builder.AddGyroscope().None();
                    builder.AddMagnetometer().None();
                    builder.AddMicrophone().None();
                    builder.AddMidi().None();
                    builder.AddPayment().None();
                    builder.AddPictureInPicture().None();
                    builder.AddSpeaker().None();
                    builder.AddSyncXHR().None();
                    builder.AddUsb().None();
                    builder.AddVR().None();
                });

            app.UseSecurityHeaders(policyCollection);

        }
    }
}
