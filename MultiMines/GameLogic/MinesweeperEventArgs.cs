using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class MinesweeperEventArgs : EventArgs
    {
        public int X { get; private set; }
        public int Y { get; private set; }
        public int UserId { get; private set; }
        public long EventId { get; private set; }


        public MinesweeperEventArgs(int x, int y, int userId, long eventId)
        {
            X = x;
            Y = y;
            UserId = userId;
            EventId = eventId;
        }
    }
}