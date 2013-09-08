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

        public User User
        {
            get;
            private set;
        }

        public MinesweeperMove(User user, int x, int y) 
        {
            User = user;
            X = x;
            Y = y;
        }
    }
}