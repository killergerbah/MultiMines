using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class Minesweeper
    {
        public MinesweeperBoard Board { get; private set; }

        public Minesweeper(int width, int height, int numMines) 
        {
            Board = new MinesweeperBoard(width, height, numMines);
        }

        public void Uncover(int i, int j)
        {
            Board.Uncover(i, j);
        }
    }
}