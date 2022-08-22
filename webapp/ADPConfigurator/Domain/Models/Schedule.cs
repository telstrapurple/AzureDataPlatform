using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class Schedule
    {
        public Schedule()
        {
            ScheduleInstance = new HashSet<ScheduleInstance>();
            Task = new HashSet<Task>();
        }

        public int ScheduleId { get; set; }
        public string ScheduleName { get; set; }
        public string ScheduleDescription { get; set; }
        public int ScheduleIntervalId { get; set; }
        public int Frequency { get; set; }
        public DateTime StartDate { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual ScheduleInterval ScheduleInterval { get; set; }
        public virtual ICollection<ScheduleInstance> ScheduleInstance { get; set; }
        public virtual ICollection<Task> Task { get; set; }
    }
}
