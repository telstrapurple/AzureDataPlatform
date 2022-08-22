using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class VwDataFactoryLogSystem
    {
        public string SystemName { get; set; }
        public string SystemCode { get; set; }
        public int SystemId { get; set; }
        public string ScheduleName { get; set; }
        public string Schedule { get; set; }
        public DateTimeOffset? StartDateTime { get; set; }
        public int? RunTimeMinute { get; set; }
        public string SystemStatus { get; set; }
        public int? TaskCount { get; set; }
    }
}
