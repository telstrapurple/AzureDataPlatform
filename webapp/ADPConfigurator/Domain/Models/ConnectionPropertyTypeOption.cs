using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class ConnectionPropertyTypeOption
    {
        public int ConnectionPropertyTypeOptionId { get; set; }
        public int ConnectionPropertyTypeId { get; set; }
        public string ConnectionPropertyTypeOptionName { get; set; }
        public string ConnectionPropertyTypeOptionDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual ConnectionPropertyType ConnectionPropertyType { get; set; }
    }
}
