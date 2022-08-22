using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class VwDataFactoryLog
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
        public string TaskName { get; set; }
        public string TaskDescription { get; set; }
        public bool TaskEnabledIndicator { get; set; }
        public bool TaskDeletedIndicator { get; set; }
        public string ScheduleName { get; set; }
        public string ScheduleDescription { get; set; }
        public int Frequency { get; set; }
        public bool ScheduleEnabledIndicator { get; set; }
        public bool ScheduleDeletedIndicator { get; set; }
        public string ScheduleIntervalName { get; set; }
        public string ScheduleIntervalDescription { get; set; }
        public bool ScheduleIntervalEnabledIndicator { get; set; }
        public bool ScheduleIntervalDeletedIndicator { get; set; }
        public string TaskTypeName { get; set; }
        public string TaskTypeDescription { get; set; }
        public bool TaskTypeEnabledIndicator { get; set; }
        public bool TaskTypeDeletedIndicator { get; set; }
        public string SystemName { get; set; }
        public string SystemDescription { get; set; }
        public string SystemCode { get; set; }
        public int SystemId { get; set; }
        public bool SystemEnabledIndicator { get; set; }
        public bool SystemDeletedIndicator { get; set; }
        public string SourceConnectionName { get; set; }
        public string SourceConnectionDescription { get; set; }
        public string TargetConnectionName { get; set; }
        public string TargetConnectionDescription { get; set; }
        public string Schedule { get; set; }
        public int? RuntimeInMins { get; set; }
    }
}
