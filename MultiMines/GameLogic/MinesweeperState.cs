using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class MinesweeperState : GameState
    {
        public MinesweeperBoard Board { get; private set; }

        public MinesweeperState(int width, int height, int numMines){
            Board = new MinesweeperBoard(width, height, numMines);
        }

        public MinesweeperState(MinesweeperBoard board)
        {
            Board = board;
        }

        public override bool Verify(MinesweeperBoard board)
        {
            return false;
        }
    }
}