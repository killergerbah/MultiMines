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

    public class MinesweeperCell : ICloneable, IEquatable<MinesweeperCell>
    {
        public int? OwnerId { get; set; }

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

        public MinesweeperCell(int x, int y, CellType type, CellStatus status)
        {
            X = x;
            Y = y;
            Type = type;
            Status = status;
        }

        public MinesweeperCell(int x, int y, CellType type, CellStatus status, int ownerId) :
            this(x, y, type, status)
        {
            OwnerId = ownerId;
        }

        public void Uncover(int ownerId)
        {
            OwnerId = ownerId;
            Status = CellStatus.Uncovered;
        }

        public object Clone()
        {
            return new MinesweeperCell(X, Y, Type, Status);
        }

        public bool Equals(MinesweeperCell other)
        {
            if (other == null)
            {
                return false;
            }
            return X == other.X && Y == other.Y && Type == other.Type && Status == other.Status;
        }
    }
}