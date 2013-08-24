using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines
{
    public class Minesweeper : Game
    {
        public MinesweeperBoard Board { get; private set; }

        public Minesweeper(long id, int width, int height, int numMines, Player[] players) : base(id, players)
        {
            Board = new MinesweeperBoard(width, height, numMines);
        }

    }
}