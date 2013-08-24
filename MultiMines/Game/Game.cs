using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines
{
    public class Game
    {
        public long Id { get; set; }

        public Player[] Players { get; private set; }

        public Game(Player[] players)
        {
            Id = new Random().Next();
            Players = players;
        }

        public Game(long id, Player[] players)
        {
            Id = id;
            Players = players;
        }
    }
}