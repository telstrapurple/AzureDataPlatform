using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class User
    {
        public User()
        {
            UserPermission = new HashSet<UserPermission>();
        }

        public string UserId { get; set; }
        public string UserName { get; set; }
        public string EmailAddress { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool AdminIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public DateTimeOffset? DateModified { get; set; }

        [Obsolete("Permissions are now administrated via AAD groups")]
        public virtual ICollection<UserPermission> UserPermission { get; set; }
    }
}
