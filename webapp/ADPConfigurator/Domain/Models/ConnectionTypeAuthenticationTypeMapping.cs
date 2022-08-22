using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class ConnectionTypeAuthenticationTypeMapping
    {
        public ConnectionTypeAuthenticationTypeMapping()
        {
            ConnectionTypeConnectionPropertyTypeMapping = new HashSet<ConnectionTypeConnectionPropertyTypeMapping>();
        }

        public int ConnectionTypeAuthenticationTypeMappingId { get; set; }
        public int ConnectionTypeId { get; set; }
        public int AuthenticationTypeId { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual AuthenticationType AuthenticationType { get; set; }
        public virtual ConnectionType ConnectionType { get; set; }
        public virtual ICollection<ConnectionTypeConnectionPropertyTypeMapping> ConnectionTypeConnectionPropertyTypeMapping { get; set; }
    }
}
