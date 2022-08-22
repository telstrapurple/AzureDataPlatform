using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class DatabaseTableRowCount
    {
        public int ConnectionId { get; set; }
        public string Schema { get; set; }
        public string TableName { get; set; }
        public long NoOfRows { get; set; }
        public DateTimeOffset DateCreated { get; set; }

        public virtual Connection Connection { get; set; }
    }
}
