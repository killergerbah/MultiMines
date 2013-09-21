using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Web;

namespace MultiMines.GameLogic
{
    [DataContract]
    public class MinesweeperController
    {
        public static TimeSpan EVENT_WINDOW = TimeSpan.FromMilliseconds(500);
        
        public event EventHandler<MinesweeperEventArgs> Uncover;
        public event EventHandler<MinesweeperEventArgs> SpecialUncover;
        public event EventHandler<MinesweeperEventArgs> Flag;
        public event EventHandler<MinesweeperEventArgs> Unflag;
        
        [DataMember]
        public MinesweeperBoard Board { get; private set; }

        public MinesweeperController(int width, int height, int numMines) 
        {
            Board = new MinesweeperBoard(width, height, numMines);
        }

        public virtual void OnUncover(MinesweeperEventArgs e)
        {
            Board.Uncover(e.X, e.Y, e.UserId);
            Uncover(this, e);
        }


        public virtual void OnFlag(MinesweeperEventArgs e)
        {
            var x = e.X;
            var y = e.Y;
            var userId = e.UserId;
            var cell = Board[x, y];
            if(cell.FlagOwnerId != null && cell.FlagOwnerId != userId)
            {
                //By default do not allow
                //different players to flag the same cell
                return;
            }
            Board.Flag(x, y, userId);
            Flag(this, e);
        }

        public virtual void OnUnflag(MinesweeperEventArgs e)
        {
            var x = e.X;
            var y = e.Y;
            if (Board[x, y].FlagOwnerId == e.UserId)
            {
                Board.Unflag(e.X, e.Y, e.UserId);
                Unflag(this, e);
            }
        }

        public virtual void OnSpecialUncover(MinesweeperEventArgs e)
        {
            Board.SpecialUncover(e.X, e.Y, e.UserId);
            SpecialUncover(this, e);
        }
    }
}