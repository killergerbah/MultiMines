using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class Minesweeper : Game
    {
        public MinesweeperBoard Board { get; private set; }

        public Minesweeper(long id)
        {
            Id = id;
        }

        public Minesweeper(long id, Player[] players) 
            : this(id)
        {
            Id = id;
        }

        public Minesweeper(long id, int width, int height, int numMines, Player[] players) 
            : this(id, players)
        {
            Board = new MinesweeperBoard(width, height, numMines);
        }

        public override GameState Transition(MinesweeperMove move)
        {
            return move.EndState;
        }

    }
}