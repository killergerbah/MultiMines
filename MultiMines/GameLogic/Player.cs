using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class User
    {
        public string Name { get; private set; }
        public long Id { get; private set; }

        public User(long id, string name)
        {
            Id = id;
            Name = name;
        }
    }
}