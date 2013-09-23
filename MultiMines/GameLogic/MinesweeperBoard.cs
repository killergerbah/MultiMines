using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Web;

namespace MultiMines.GameLogic
{
    [DataContract]
    public class MinesweeperBoard : ICloneable
    {
        [DataMember]
        private MinesweeperCell[,] _board;

        [DataMember]
        public int Width { get; private set; }

        [DataMember]
        public int Height { get; private set; }

        [DataMember]
        public int NumMines { get; private set; }

        public int Count
        {
            get
            {
                return Width * Height;
            }
        }

        public MinesweeperBoard(int width, int height)
        {
            Width = width;
            Height = height;
            _board = new MinesweeperCell[Height + 2, Width + 2];
            NumMines = 0;

            _populateBoard();
        }

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
                    if (rand.NextDouble() < (double) NumMines / index)
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

        public void Uncover(int i, int j, int userId)
        {
            var cell = this[i, j];
            if (cell.Type == CellType.Mined)
            {
                //do not uncover mined cells
                return;
            }

            Queue<MinesweeperCell> toCascade = new Queue<MinesweeperCell>();
            toCascade.Enqueue(cell);
            while (toCascade.Any())
            {
                cell = toCascade.Dequeue();
                if (cell.Status == CellStatus.Uncovered || cell.FlagOwnerId != null) //skip if flagged
                {
                    continue;
                }

                cell.Uncover(userId);
                var neighbors = _neighbors(cell.X, cell.Y);
                if (!neighbors.Where((x) =>
                {
                    return x.Type == CellType.Mined;
                }).Any())
                {
                    foreach(MinesweeperCell neighbor in neighbors)
                    {
                        toCascade.Enqueue(neighbor);
                    }
                }
            }
        }

        public void SpecialUncover(int i, int j, int userId)
        {
            var cell = this[i, j];
            if (cell.Status == CellStatus.Uncovered)
            {
                var neighbors = _neighbors(i, j);
                var numFlags = neighbors.Where((x) =>
                    {
                        return x.Status == CellStatus.Covered &&
                            x.FlagOwnerId != null;
                    }).ToArray().Length;
                var numMinedNeighbors = neighbors.Where((x) =>
                    {
                        return x.Type == CellType.Mined;
                    }).ToArray().Length;
                if (numFlags == numMinedNeighbors)
                {
                    var toCascade = neighbors.Where((x) =>
                    {
                        return x.Status == CellStatus.Covered &&
                            x.FlagOwnerId == null;
                    });
                    foreach (MinesweeperCell neighbor in toCascade)
                    {
                        Uncover(neighbor.X, neighbor.Y, userId);
                    }
                }
            }
        }

        public void Flag(int i, int j, int userId)
        {
            this[i, j].Flag(userId);   
        }

        public void Unflag(int i, int j, int userId)
        {
            this[i, j].Unflag(userId);
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
                this[i - 1, j + 1],
                this[i, j + 1],
                this[i + 1,j + 1]
            }.Where((x) => { return x != null; }).ToList();
        }

        public int GetNumFlags(int userId)
        {
            var numFlags = 0;
            for (var i = 0; i < Height; i++)
            {
                for (var j = 0; j < Width; j++)
                {
                    if (this[i, j].FlagOwnerId == userId)
                    {
                        numFlags++;
                    }
                }
            }
            return numFlags;
        }

        public object Clone()
        {
            var clone = new MinesweeperBoard(Width, Height);
            for (var i = 0; i < Height; i++)
            {
                for (var j = 0; j < Width; j++)
                {
                    clone[i, j] = (MinesweeperCell) this[i, j].Clone();
                }
            }
            return clone;
        }
    }
    /*
    public class MinesweeperBoardEnumerator : IEnumerator<MinesweeperCell>
    {
        public MinesweeperBoard _board;
        int position = -1;
 
        public MinesweeperBoardEnumerator(MinesweeperBoard board)
        {
            _board = board;
        }

        public bool MoveNext()
        {
            position++;
            return position < _board.Count;
        }

        public void Reset()
        {
            position = -1;
        }

        object IEnumerator.Current
        {
            get
            {
                return Current;
            }
        }

        public MinesweeperCell Current
        {
            get
            {
                try
                {
                    return _board[position / _board.Width, position % _board.Width];
                }
                catch (InvalidOperationException)
                {
                    throw new InvalidOperationException();
                }
            }
        }

        void IDisposable.Dispose() { }
    }*/
}