using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class GenericConfig
    {
        public int GenericConfigId { get; set; }
        public string GenericConfigName { get; set; }
        public string GenericConfigDescription { get; set; }
        public string GenericConfigValue { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
    }
}
