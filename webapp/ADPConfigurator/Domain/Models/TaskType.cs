using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class TaskType
    {
        public TaskType()
        {
            Task = new HashSet<Task>();
            TaskTypeTaskPropertyTypeMapping = new HashSet<TaskTypeTaskPropertyTypeMapping>();
        }

        public int TaskTypeId { get; set; }
        public string TaskTypeName { get; set; }
        public string TaskTypeDescription { get; set; }
        public bool EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public bool? ScriptIndicator { get; set; }
        public bool? FileLoadIndicator { get; set; }
        public bool? DatabaseLoadIndicator { get; set; }
        public string RunType { get; set; }

        public virtual ICollection<Task> Task { get; set; }
        public virtual ICollection<TaskTypeTaskPropertyTypeMapping> TaskTypeTaskPropertyTypeMapping { get; set; }
    }
}
