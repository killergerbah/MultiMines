using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public enum CellType
    {
        Safe,
        Mined
    }

    public enum CellStatus
    {
        Unflagged,
        Flagged,
        Uncovered
    }

    public class MinesweeperCell
    {
        public CellType Type { get; set; }

        public CellStatus Status { get; set; }

        public int X { get; private set; }

        public int Y { get; private set; }

        public MinesweeperCell(int x, int y, CellType type)
        {
            X = x;
            Y = y;
            Type = type;
            Status = CellStatus.Unflagged;
        }

        public void Uncover()
        {
            Status = CellStatus.Uncovered;
        }
    }
}