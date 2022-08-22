using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class ScheduleInstance
    {
        public ScheduleInstance()
        {
            TaskInstance = new HashSet<TaskInstance>();
        }

        public int ScheduleInstanceId { get; set; }
        public int ScheduleId { get; set; }
        public DateTime RunDate { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual Schedule Schedule { get; set; }
        public virtual ICollection<TaskInstance> TaskInstance { get; set; }
    }
}
