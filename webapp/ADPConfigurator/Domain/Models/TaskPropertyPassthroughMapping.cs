using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class TaskPropertyPassthroughMapping
    {
        public int TaskPropertyPassthroughMappingId { get; set; }
        public int TaskId { get; set; }
        public int TaskPassthroughId { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual Task Task { get; set; }
        public virtual Task TaskPassthrough { get; set; }
    }
}
