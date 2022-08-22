using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class FileInterimDataType
    {
        public FileInterimDataType()
        {
            FileColumnMapping = new HashSet<FileColumnMapping>();
        }

        public int FileInterimDataTypeId { get; set; }
        public string FileInterimDataTypeName { get; set; }
        public string FileInterimDataTypeDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual ICollection<FileColumnMapping> FileColumnMapping { get; set; }
    }
}
