using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class DatabaseTableConstraint
    {
        public int ConnectionId { get; set; }
        public string Schema { get; set; }
        public string TableName { get; set; }
        public string ColumnName { get; set; }
        public int? ConstraintPosition { get; set; }
        public string ConstraintType { get; set; }
        public string ConstraintName { get; set; }
        public DateTimeOffset DateCreated { get; set; }

        public virtual Connection Connection { get; set; }
    }
}
