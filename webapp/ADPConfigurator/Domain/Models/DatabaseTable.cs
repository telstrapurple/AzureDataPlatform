namespace ADPConfigurator.Domain.Models
{
    public partial class DatabaseTable
    {
        public string SourceType { get; set; }
        public string SourceSystem { get; set; }
        public string Schema { get; set; }
        public string TableName { get; set; }
    }
}
