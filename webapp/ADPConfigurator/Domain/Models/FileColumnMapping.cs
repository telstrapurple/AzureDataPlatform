using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class FileColumnMapping
    {
        public int FileColumnMappingId { get; set; }
        public int TaskId { get; set; }
        public string SourceColumnName { get; set; }
        public string TargetColumnName { get; set; }
        public int FileInterimDataTypeId { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public string DataLength { get; set; }

        public virtual FileInterimDataType FileInterimDataType { get; set; }
        public virtual Task Task { get; set; }
    }
}
