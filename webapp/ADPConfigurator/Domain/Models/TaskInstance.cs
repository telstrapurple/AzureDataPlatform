using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class TaskInstance
    {
        public TaskInstance()
        {
            CdcloadLog = new HashSet<CdcloadLog>();
            DataFactoryLog = new HashSet<DataFactoryLog>();
            FileLoadLog = new HashSet<FileLoadLog>();
            IncrementalLoadLog = new HashSet<IncrementalLoadLog>();
        }

        public int TaskInstanceId { get; set; }
        public int TaskId { get; set; }
        public int ScheduleInstanceId { get; set; }
        public DateTime RunDate { get; set; }
        public int TaskResultId { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual ScheduleInstance ScheduleInstance { get; set; }
        public virtual Task Task { get; set; }
        public virtual TaskResult TaskResult { get; set; }
        public virtual ICollection<CdcloadLog> CdcloadLog { get; set; }
        public virtual ICollection<DataFactoryLog> DataFactoryLog { get; set; }
        public virtual ICollection<FileLoadLog> FileLoadLog { get; set; }
        public virtual ICollection<IncrementalLoadLog> IncrementalLoadLog { get; set; }
    }
}
