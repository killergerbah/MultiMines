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

        public User[] Users { get; private set; }

        public User Winner { get; private set; }

        public Minesweeper(long id, User[] users) 
        {
            Id = id;
            Users = users;
        }

        public Minesweeper(long id, MinesweeperState state, User[] users)
            : this(id, users)
        {
            Id = id;
            State = state;
            Users = users;
        }

        public Minesweeper(long id, int width, int height, int numMines, User[] users) 
            : this(id, users)
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