using System;
using System.Collections.Generic;
using System.Linq;

namespace ADPConfigurator.Domain
{
    /// <summary>
    /// Used to create a textual representation of changes occurring
    /// between two objects of the same type.
    /// 
    /// See ADPConfigurator.Domain.System.Diff() for example usage.
    /// </summary>
    public class EntityDiff
    {
        public EntityDiff()
        {
            _nestStack = new Stack<IList<string>>();
            _nestStack.Push(new List<string>());
        }

        const string INDENT = "    ";

        private Stack<IList<string>> _nestStack; 

        private int _indentationLevel = 0;

        public void Nest(string header, Action nestedDiffFunction)
        {
            
            _nestStack.Push(new List<string>());
            _indentationLevel++;
            nestedDiffFunction();
            _indentationLevel--;

            var inner = _nestStack.Pop();
            if (_nestStack.Count != 0)
            {
                if (inner.Count != 0)
                {
                    AddHeader(header);
                }
                var top = _nestStack.Pop();
                _nestStack.Push(top.Concat(inner).ToList());
            }
        }

        public void AddHeader(string header)
        {
            _addContent($"{header}:");
        }

        public void AddLine(string propertyName, object oldValue, object newValue)
        {
            if (oldValue == null && newValue != null)
            {
                AddCreation(propertyName, newValue);
            }
            else if (newValue == null && oldValue != null)
            {
                AddDeletion(propertyName);
            }
            else if (oldValue == null && newValue == null)
            {
                return;
            }
            else if (oldValue.ToString() == newValue.ToString())
            {
                return;
            }
            else
            {
                _addContent($"{propertyName}: {oldValue} => {newValue}");
            }
        }

        public void AddDeletion(string propertyName)
        {
            _addContent($"Removed: {propertyName}");
        }

        public void AddCreation(string propertyName, object newValue)
        {
            _addContent($"Added {propertyName}: {newValue}");
        }

        public void AddRaw(string content)
        {
            _addContent(content);
        }

        private void _addContent(string newContent)
        {
            var line = "";
            for (var i = 0; i < _indentationLevel; i++)
            {
                line += INDENT;
            }
            line += newContent;

            _nestStack.Peek().Add(line);
        }

        public override string ToString()
        {
            string content = "";
            foreach (var line in _nestStack.Peek())
            {
                content += $"{line}\r\n";
            }
            return content;
        }
    }
}
