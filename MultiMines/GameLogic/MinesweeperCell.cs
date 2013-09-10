﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
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
        Covered,
        Uncovered
    }

    [DataContract]
    public class MinesweeperCell : ICloneable, IEquatable<MinesweeperCell>
    {
        [DataMember]
        public int? OwnerId { get; set; }

        [DataMember]
        public HashSet<int> FlagOwnerIds { get; set; } //using list because set is not serializable

        [DataMember]
        public CellType Type { get; set; }

        [DataMember]
        public CellStatus Status { get; set; }

        [DataMember]
        public int X { get; private set; }

        [DataMember]
        public int Y { get; private set; }

        public MinesweeperCell(int x, int y, CellType type)
        {
            X = x;
            Y = y;
            Type = type;
            Status = CellStatus.Covered;
            FlagOwnerIds = new HashSet<int>();
        }

        public MinesweeperCell(int x, int y, CellType type, CellStatus status)
        {
            X = x;
            Y = y;
            Type = type;
            Status = status;
            FlagOwnerIds = new HashSet<int>();
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

        public void Flag(int ownerId)
        {
            FlagOwnerIds.Add(ownerId);

        }

        public void Unflag(int ownerId)
        {
            FlagOwnerIds.Remove(ownerId);
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