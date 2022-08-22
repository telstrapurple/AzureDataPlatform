using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace Migrator
{
    internal static class HashtableExtensions
    {
        public static Dictionary<string, string> ToDictionary(this Hashtable table)
        {
            return table
                .Cast<DictionaryEntry>()
                .ToDictionary(kvp => (string)kvp.Key, kvp => (string)kvp.Value);
        }
    }
}
