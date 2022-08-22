using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class AuthenticationType
    {
        public AuthenticationType()
        {
            Connection = new HashSet<Connection>();
            ConnectionTypeAuthenticationTypeMapping = new HashSet<ConnectionTypeAuthenticationTypeMapping>();
        }

        public int AuthenticationTypeId { get; set; }
        public string AuthenticationTypeName { get; set; }
        public string AuthenticationTypeDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual ICollection<Connection> Connection { get; set; }
        public virtual ICollection<ConnectionTypeAuthenticationTypeMapping> ConnectionTypeAuthenticationTypeMapping { get; set; }
    }
}
