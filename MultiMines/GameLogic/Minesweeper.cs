using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class Minesweeper : IGame<MinesweeperState, MinesweeperMove>
    {
        public MinesweeperBoard Board { get; private set; }

        public long Id { get; private set; }

        public MinesweeperState State { get; private set; }

        public Player[] Players { get; private set; }

        public Player Winner { get; private set; }

        public Minesweeper(long id, Player[] players) 
        {
            Id = id;
            Players = players;
        }

        public Minesweeper(long id, MinesweeperState state, Player[] players) 
            : this(id, players)
        {
            Id = id;
            State = state;
            Players = players;
        }

        public Minesweeper(long id, int width, int height, int numMines, Player[] players) 
            : this(id, players)
        {
            Board = new MinesweeperBoard(width, height, numMines);
        }

        public MinesweeperState Transition(MinesweeperMove move)
        {
            if (State == null)
            {
                throw new InvalidOperationException("This game has no state");
            }
            State.Board.Uncover(move.X, move.Y);
            State.IncrementId();
            return State;
        }

        public void SetInitialState(MinesweeperState state)
        {
            if (state != null)
            {
                throw new InvalidOperationException("The state for this game is already set");
            }
            State = state;
            return;
        }

    }
}