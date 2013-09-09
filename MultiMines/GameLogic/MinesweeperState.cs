using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class MinesweeperState
    {
        public MinesweeperBoard Board { get; private set; }

        public string Id { get; private set; }

        public MinesweeperState(string id, MinesweeperBoard board)
        {
            Id = id;
            Board = board;
        }
    }
}