using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class IncrementalLoadLog
    {
        public int IncrementalLoadLogId { get; set; }
        public int TaskInstanceId { get; set; }
        public string EntityName { get; set; }
        public string IncrementalColumn { get; set; }
        public string LatestValue { get; set; }
        public bool SuccessIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public DateTimeOffset? DateModified { get; set; }

        public virtual TaskInstance TaskInstance { get; set; }
    }
}
