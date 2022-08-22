using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class ConnectionProperty
    {
        public int ConnectionPropertyId { get; set; }
        public int ConnectionPropertyTypeId { get; set; }
        public int ConnectionId { get; set; }
        public string ConnectionPropertyValue { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual Connection Connection { get; set; }
        public virtual ConnectionPropertyType ConnectionPropertyType { get; set; }
    }
}
