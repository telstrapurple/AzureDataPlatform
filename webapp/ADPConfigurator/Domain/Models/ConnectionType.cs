using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class ConnectionType
    {
        public ConnectionType()
        {
            Connection = new HashSet<Connection>();
            ConnectionTypeAuthenticationTypeMapping = new HashSet<ConnectionTypeAuthenticationTypeMapping>();
        }

        public int ConnectionTypeId { get; set; }
        public string ConnectionTypeName { get; set; }
        public string ConnectionTypeDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public bool DatabaseConnectionIndicator { get; set; }
        public bool FileConnectionIndicator { get; set; }
        public bool CrmconnectionIndicator { get; set; }
        public bool OdbcconnectionIndicator { get; set; }

        public virtual ICollection<Connection> Connection { get; set; }
        public virtual ICollection<ConnectionTypeAuthenticationTypeMapping> ConnectionTypeAuthenticationTypeMapping { get; set; }
    }
}
