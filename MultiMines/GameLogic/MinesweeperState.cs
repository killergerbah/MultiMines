using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class MinesweeperState : IEquatable<MinesweeperState>
    {
        public MinesweeperBoard Board { get; private set; }

        public long Id { get; private set; }

        public MinesweeperState(int width, int height, int numMines){
            Id = 0;
            Board = new MinesweeperBoard(width, height, numMines);
        }

        public MinesweeperState(long id, MinesweeperBoard board)
        {
            Id = id;
            Board = board;
        }

        public void IncrementId()
        {
            Id++;
        }
        public bool Equals(MinesweeperState state)
        {
            return false;
        }
    }
}