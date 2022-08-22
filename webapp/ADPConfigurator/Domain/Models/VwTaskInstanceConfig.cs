namespace ADPConfigurator.Domain.Models
{
    public partial class VwTaskInstanceConfig
    {
        public string ConnectionStage { get; set; }
        public int TaskInstanceId { get; set; }
        public string SystemPropertyType { get; set; }
        public string SystemPropertyValue { get; set; }
        public string TaskType { get; set; }
        public string TaskPropertyType { get; set; }
        public string TaskPropertyValue { get; set; }
        public string ConnectionType { get; set; }
        public string AuthenticationType { get; set; }
        public string ConnectionPropertyType { get; set; }
        public string ConnectionPropertyValue { get; set; }
    }
}
