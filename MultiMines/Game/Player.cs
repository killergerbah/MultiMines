using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines
{
    public class Player
    {
        public string ConnectionId { get; private set; }
        public string Name { get; private set; }

        public Player(string connectionId, string name)
        {
            ConnectionId = connectionId;
            Name = name;
        }
    }
}