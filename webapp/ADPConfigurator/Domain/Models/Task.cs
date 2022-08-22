using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class Task
    {
        public Task()
        {
            FileColumnMapping = new HashSet<FileColumnMapping>();
            TaskInstance = new HashSet<TaskInstance>();
            TaskProperty = new HashSet<TaskProperty>();
            TaskPropertyPassthroughMappingTask = new HashSet<TaskPropertyPassthroughMapping>();
            TaskPropertyPassthroughMappingTaskPassthrough = new HashSet<TaskPropertyPassthroughMapping>();
        }

        public int TaskId { get; set; }
        public string TaskName { get; set; }
        public string TaskDescription { get; set; }
        public int SystemId { get; set; }
        public int ScheduleId { get; set; }
        public int TaskTypeId { get; set; }
        public int SourceConnectionId { get; set; }
        public int? EtlconnectionId { get; set; }
        public int? StageConnectionId { get; set; }
        public int? TargetConnectionId { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public int? TaskOrderId { get; set; }

        public virtual Connection Etlconnection { get; set; }
        public virtual Schedule Schedule { get; set; }
        public virtual Connection SourceConnection { get; set; }
        public virtual Connection StageConnection { get; set; }
        public virtual System System { get; set; }
        public virtual Connection TargetConnection { get; set; }
        public virtual TaskType TaskType { get; set; }
        public virtual ICollection<FileColumnMapping> FileColumnMapping { get; set; }
        public virtual ICollection<TaskInstance> TaskInstance { get; set; }
        public virtual ICollection<TaskProperty> TaskProperty { get; set; }
        public virtual ICollection<TaskPropertyPassthroughMapping> TaskPropertyPassthroughMappingTask { get; set; }
        public virtual ICollection<TaskPropertyPassthroughMapping> TaskPropertyPassthroughMappingTaskPassthrough { get; set; }
    }
}
