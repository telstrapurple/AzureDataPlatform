using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class DataFactoryLog
    {
        public int DataFactoryLogId { get; set; }
        public int? TaskInstanceId { get; set; }
        public string LogType { get; set; }
        public string DataFactoryName { get; set; }
        public string PipelineName { get; set; }
        public string PipelineRunId { get; set; }
        public string PipelineTriggerId { get; set; }
        public string PipelineTriggerName { get; set; }
        public DateTimeOffset? PipelineTriggerTime { get; set; }
        public string PipelineTriggerType { get; set; }
        public string ActivityName { get; set; }
        public string OutputMessage { get; set; }
        public string ErrorMessage { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public bool EmailSentIndicator { get; set; }
        public int? FileLoadLogId { get; set; }

        public virtual FileLoadLog FileLoadLog { get; set; }
        public virtual TaskInstance TaskInstance { get; set; }
    }
}
