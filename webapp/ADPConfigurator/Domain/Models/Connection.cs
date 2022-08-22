using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class Connection
    {
        public Connection()
        {
            ConnectionProperty = new HashSet<ConnectionProperty>();
            DatabaseTableColumn = new HashSet<DatabaseTableColumn>();
            DatabaseTableConstraint = new HashSet<DatabaseTableConstraint>();
            DatabaseTableRowCount = new HashSet<DatabaseTableRowCount>();
            TaskEtlconnection = new HashSet<Task>();
            TaskSourceConnection = new HashSet<Task>();
            TaskStageConnection = new HashSet<Task>();
            TaskTargetConnection = new HashSet<Task>();
        }

        public int ConnectionId { get; set; }
        public string ConnectionName { get; set; }
        public string ConnectionDescription { get; set; }
        public int ConnectionTypeId { get; set; }
        public bool? EnabledIndicator { get; set; }
        public string SystemCode { get; set; }
        public bool Generic { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public int? AuthenticationTypeId { get; set; }

        public virtual AuthenticationType AuthenticationType { get; set; }
        public virtual ConnectionType ConnectionType { get; set; }
        public virtual ICollection<ConnectionProperty> ConnectionProperty { get; set; }
        public virtual ICollection<DatabaseTableColumn> DatabaseTableColumn { get; set; }
        public virtual ICollection<DatabaseTableConstraint> DatabaseTableConstraint { get; set; }
        public virtual ICollection<DatabaseTableRowCount> DatabaseTableRowCount { get; set; }
        public virtual ICollection<Task> TaskEtlconnection { get; set; }
        public virtual ICollection<Task> TaskSourceConnection { get; set; }
        public virtual ICollection<Task> TaskStageConnection { get; set; }
        public virtual ICollection<Task> TaskTargetConnection { get; set; }
    }
}
