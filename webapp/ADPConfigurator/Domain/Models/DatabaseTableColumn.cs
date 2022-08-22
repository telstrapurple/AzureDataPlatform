using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class DatabaseTableColumn
    {
        public int ConnectionId { get; set; }
        public string Schema { get; set; }
        public string TableName { get; set; }
        public int ColumnId { get; set; }
        public string ColumnName { get; set; }
        public string DataType { get; set; }
        public decimal? DataLength { get; set; }
        public decimal? DataPrecision { get; set; }
        public decimal? DataScale { get; set; }
        public string Nullable { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string ComputedIndicator { get; set; }

        public virtual Connection Connection { get; set; }
    }
}
