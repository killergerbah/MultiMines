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
        CoveredUnflagged,
        Flagged,
        Uncovered
    }

    public class Cell
    {
        public CellType Type { get; set; }

        public CellStatus Status { get; set; }

        public int X { get; private set; }

        public int Y { get; private set; }

        public Cell(int x, int y, CellType type)
        {
            X = x;
            Y = y;
            Type = type;
            Status = CellStatus.CoveredUnflagged;
        }

        public void Uncover()
        {
            Status = CellStatus.Uncovered;
        }
    }
}