using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class ConnectionTypeConnectionPropertyTypeMapping
    {
        public int ConnectionTypeConnectionPropertyTypeMappingId { get; set; }
        public int ConnectionPropertyTypeId { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public int? ConnectionTypeAuthenticationTypeMappingId { get; set; }

        public virtual ConnectionPropertyType ConnectionPropertyType { get; set; }
        public virtual ConnectionTypeAuthenticationTypeMapping ConnectionTypeAuthenticationTypeMapping { get; set; }
    }
}
