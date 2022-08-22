using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class ScheduleInterval
    {
        public ScheduleInterval()
        {
            Schedule = new HashSet<Schedule>();
        }

        public int ScheduleIntervalId { get; set; }
        public string ScheduleIntervalName { get; set; }
        public string ScheduleIntervalDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual ICollection<Schedule> Schedule { get; set; }
    }
}
