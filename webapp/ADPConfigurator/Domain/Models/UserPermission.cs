using System;

namespace ADPConfigurator.Domain.Models
{
    [Obsolete("Permissions are now administrated via AAD groups")]
    public partial class UserPermission
    {
        public int UserPermissionId { get; set; }
        public string UserId { get; set; }
        public int SystemId { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }

        public virtual System System { get; set; }
        public virtual User User { get; set; }
    }
}
