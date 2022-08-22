using System;
using System.Collections.Generic;
using System.Text;

namespace ADPConfigurator.Domain.Models
{
    /// <summary>
    /// Captures the information necessary for our pipeline to
    /// set the Access Control Lists we define in our data lakes
    /// 
    /// Note - properties in this class break .Net naming conventions
    /// because they must be serialised into the format expected by our
    /// pipeline
    /// </summary>
    public class AclSpecification
    {
        private readonly string[] ZONES = new string[] { "Raw", "Delta", "Staging", "Schema" };

        public AclSpecification(
            string environment,
            string serviceEndpoint,
            string serviceCode,
            string platformAdminGroup,
            string datafactoryServicePrincipal,
            string databricksServicePrincipal,
            string readonlyGroup,
            string localAdminGroup, 
            string engineerGroup)
        {
            this.serviceEndpoint = serviceEndpoint;
            aclPermissions = new List<AclPermission>();
            var restrictedAccess = environment == "Production";

            foreach (var zone in ZONES)
            {
                var datalakePath = $"datalakestore/adp/{zone}/{serviceCode}";
                if (readonlyGroup != null)
                {
                    aclPermissions.Add(new AclPermission
                    {
                        objectType = "Group",
                        permission = "r-x",
                        objectID = readonlyGroup,
                        path = datalakePath,
                    });
                }
                if (localAdminGroup != null)
                {
                    aclPermissions.Add(new AclPermission
                    {
                        objectType = "Group",
                        permission = restrictedAccess ? "r-x" : "rwx",
                        objectID = localAdminGroup,
                        path = datalakePath,
                    });
                }
                if (engineerGroup != null)
                {
                    aclPermissions.Add(new AclPermission
                    {
                        objectType = "Group",
                        permission = restrictedAccess ? "r-x" : "rwx",
                        objectID = engineerGroup,
                        path = datalakePath,
                    });
                }
                aclPermissions.Add(new AclPermission
                {
                    objectType = "Group",
                    permission = "rwx",
                    objectID = platformAdminGroup,
                    path = datalakePath,
                });
                aclPermissions.Add(new AclPermission
                {
                    objectType = "Group",
                    permission = "rwx",
                    objectID = datafactoryServicePrincipal,
                    path = datalakePath,
                });
                aclPermissions.Add(new AclPermission
                {
                    objectType = "Group",
                    permission = "rwx",
                    objectID = databricksServicePrincipal,
                    path = datalakePath,
                });
            }
        }

        public string serviceEndpoint { get; set; }

        public IList<AclPermission> aclPermissions { get; }
    }

    public class AclPermission
    {
        private string _objectType;

        public string objectType {
            get
            {
                return _objectType;
            }
            
            set
            {
                if (!Array.Exists(new string[] { "User", "Group", "ServicePrincipal" }, x => x == value))
                {
                    throw new InvalidOperationException("Invalid object type for acl permission");
                }
                _objectType = value;
            }
        }

        public string objectID { get; set; }

        public string permission { get; set; }

        public string path { get; set; }
    }
}
