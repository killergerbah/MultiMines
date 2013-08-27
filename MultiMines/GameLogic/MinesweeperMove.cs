using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class MinesweeperMove
    {
        public int X { get; private set; }

        public int Y { get; private set; }

        public Player Player
        {
            get;
            private set;
        }

        public MinesweeperMove(Player player, int x, int y) 
        {
            Player = player;
            X = x;
            Y = y;
        }
    }
}