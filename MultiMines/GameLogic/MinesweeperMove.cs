using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class MinesweeperMove : Move
    {
        private Cell _cell;

        public override MinesweeperState StartState
        {
            get;
            private set;
        }

        public override Player Player
        {
            get;
            private set;
        }

        public MinesweeperMove(Player player, MinesweeperState startState, Cell cell) 
        {
            Player = player;
            StartState = startState;
            _cell = cell;
        }

        public override GameState EndState
        {
            get 
            {
                return new MinesweeperState(Uncover(StartState.Board, _cell.X, _cell.Y));
            }
        }


        public MinesweeperBoard Uncover(MinesweeperBoard board, int i, int j)
        {
            var cell = board[i, j];
            if (cell.Status == CellStatus.Uncovered)
            {
                return board;
            }
            if (cell.Type == CellType.Mined)
            {
                cell.Uncover();
                return board;
            }

            var uncovered = new List<Cell>();
            Queue<Cell> toCascade = new Queue<Cell>();
            toCascade.Enqueue(cell);
            while (toCascade.Any())
            {
                cell = toCascade.Dequeue();
                var neighbors = _neighbors(board, cell.X, cell.Y);
                if (!neighbors.Where((x) =>
                {
                    return x.Type == CellType.Mined;
                }).Any())
                {
                    cell.Uncover();
                    uncovered.Add(cell);
                    neighbors.ForEach((x) => { toCascade.Enqueue(x); });
                }
            }

            return board;
        }

        private List<Cell> _neighbors(MinesweeperBoard board, int i, int j)
        {
            return new Cell[]
            {
                board[i - 1, j - 1],
                board[i, j - 1],
                board[i + 1, j - 1],
                board[i - 1, j],
                board[i + 1, j],
                board[i + 1, j - 1],
                board[i + 1, j],
                board[i + 1,j + 1]
            }.Where((x) => { return x != null; }).ToList();
        }
    }
}