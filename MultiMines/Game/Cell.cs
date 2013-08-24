using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines
{
    public enum CellType
    {
        Safe,
        Mined
    }

    public enum CellStatus
    {
        Flagged,
        Unflagged
    }

    public class Cell
    {
        public CellType Type { get; set; }

        public CellStatus Status { get; set; }

        public Cell(CellType type)
        {
            Type = type;
            Status = CellStatus.Unflagged;
        }
    }
}