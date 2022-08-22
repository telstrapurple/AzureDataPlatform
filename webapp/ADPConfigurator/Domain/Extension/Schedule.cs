using System.ComponentModel.DataAnnotations.Schema;

// ReSharper disable once CheckNamespace - must match other 'side' of the partial class
namespace ADPConfigurator.Domain.Models
{
    public partial class Schedule
    {
        [NotMapped]
        public bool Enabled
        {
            get
            {
                // Enabled has default value == true
                return EnabledIndicator.HasValue ? EnabledIndicator.Value : true;
            }
            set
            {
                EnabledIndicator = value;
            }
        }

    }
}
