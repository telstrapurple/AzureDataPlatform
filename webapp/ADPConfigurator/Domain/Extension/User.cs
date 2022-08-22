using System.ComponentModel.DataAnnotations.Schema;

// ReSharper disable once CheckNamespace - must match other 'side' of the partial class
namespace ADPConfigurator.Domain.Models
{
    public partial class User
    {
        [NotMapped]
        public int NumberOfSystems => UserPermission.Count;        
    }
}
