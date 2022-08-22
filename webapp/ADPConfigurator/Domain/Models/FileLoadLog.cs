using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class FileLoadLog
    {
        public FileLoadLog()
        {
            DataFactoryLog = new HashSet<DataFactoryLog>();
        }

        public int FileLoadLogId { get; set; }
        public int TaskInstanceId { get; set; }
        public string FilePath { get; set; }
        public string FileName { get; set; }
        public DateTimeOffset FileLastModifiedDate { get; set; }
        public bool SuccessIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public string TargetFilePath { get; set; }
        public string TargetFileName { get; set; }

        public virtual TaskInstance TaskInstance { get; set; }
        public virtual ICollection<DataFactoryLog> DataFactoryLog { get; set; }
    }
}
