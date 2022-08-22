using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class CdcloadLog
    {
        public int CdcloadLogId { get; set; }
        public int TaskInstanceId { get; set; }
        public byte[] LatestLsnvalue { get; set; }
        public bool SuccessIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public bool? DeletedIndicator { get; set; }

        public virtual TaskInstance TaskInstance { get; set; }
    }
}
