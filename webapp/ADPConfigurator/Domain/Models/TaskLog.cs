using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class TaskLog
    {
        public int TaskLogId { get; set; }
        public int TaskInstanceId { get; set; }
        public string LogType { get; set; }
        public string LogMessage { get; set; }
        public string LogOutput { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }

        public virtual TaskInstance TaskInstance { get; set; }
    }
}
