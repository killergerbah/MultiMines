using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Web;

namespace MultiMines.GameLogic
{
    [DataContract]
    public class MinesweeperBoard
    {
        [DataMember]
        private MinesweeperCell[,] _board;

        [DataMember]
        public int Width { get; private set; }

        [DataMember]
        public int Height { get; private set; }

        [DataMember]
        public int NumMines { get; private set; }

        public MinesweeperBoard(int width, int height, int numMines)
        {
            Width = Math.Max(width, 1);
            Height = Math.Max(height, 1);
            _board = new MinesweeperCell[Height + 2, Width + 2];
            NumMines = Math.Min(Math.Max(numMines, 0), Width * Height);
            
            _populateBoard();
        }

        private void _populateBoard()
        {
            var rand = new Random();
            var mineProbability = (double) NumMines / ( Width * Height );
            var mined = new MinesweeperCell[NumMines];
            var currNumMines = 0;
            for (var i = 0; i < Height; i++)
            {
                for (var j = 0; j < Width; j++)
                {
                    var index = i * Width + j;
                    if (index < NumMines)
                    {
                        var cell = new MinesweeperCell(i, j, CellType.Mined);
                        this[i, j] = cell;
                        mined[currNumMines] = cell;
                        currNumMines++;
                        continue;
                    }
                    if (rand.NextDouble() < mineProbability)
                    {
                        //swap current cell randomly into the list of mined cells
                        var select = rand.Next(mined.Length);
                        mined[select].Type = CellType.Safe;
                        this[i, j] = new MinesweeperCell(i, j, CellType.Mined);
                        mined[select] = this[i, j];
                        continue;
                    }
                    this[i, j] = new MinesweeperCell(i, j, CellType.Safe);
                }
            }
        }

        public MinesweeperCell this[int i, int j]{
            get { return _board[i + 1, j + 1]; }
            set { _board[i + 1, j + 1] = value; }
        }

        //Returns true if cell at position i, j is a mine
        public bool Uncover(int i, int j)
        {
            var cell = this[i, j];
            if (cell.Type == CellType.Mined)
            {
                return true;
            }

            Queue<MinesweeperCell> toCascade = new Queue<MinesweeperCell>();
            toCascade.Enqueue(cell);
            while (toCascade.Any())
            {
                cell = toCascade.Dequeue();
                if (cell.Status == CellStatus.Uncovered ||
                    cell.Status == CellStatus.Flagged)
                {
                    continue;
                }

                cell.Uncover();
                var neighbors = _neighbors(cell.X, cell.Y);
                if (!neighbors.Where((x) =>
                {
                    return x.Type == CellType.Mined;
                }).Any())
                {
                    neighbors.ForEach((x) => { toCascade.Enqueue(x); });
                }
            }
            return false;
        }

        private List<MinesweeperCell> _neighbors(int i, int j)
        {
            return new MinesweeperCell[]
            {
                this[i - 1, j - 1],
                this[i, j - 1],
                this[i + 1, j - 1],
                this[i - 1, j],
                this[i + 1, j],
                this[i + 1, j - 1],
                this[i + 1, j],
                this[i + 1,j + 1]
            }.Where((x) => { return x != null; }).ToList();
        }
    }
}