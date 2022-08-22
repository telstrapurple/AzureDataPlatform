using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class TaskResult
    {
        public TaskResult()
        {
            TaskInstance = new HashSet<TaskInstance>();
        }

        public int TaskResultId { get; set; }
        public string TaskResultName { get; set; }
        public string TaskResultDescription { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public bool? RetryIndicator { get; set; }

        public virtual ICollection<TaskInstance> TaskInstance { get; set; }
    }
}
