using System;

namespace ADPConfigurator.Domain.Models
{
    /// <summary>
    /// Not mapped to entity framework - sits in a different db schema
    /// and is only used to compare whether two environments have had
    /// the same migrations run
    /// </summary>
    public class Migration
    {
        public string Id { get; set; }

        public string ScriptName { get; set; }

        public DateTime Applied { get; set; }
    }
}