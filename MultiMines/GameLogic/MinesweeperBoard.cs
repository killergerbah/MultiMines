using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class MinesweeperBoard 
    {
        private Cell[,] _board;

        public int Width { get; private set; }

        public int Height { get; private set; }

        public int NumMines { get; private set; }

        public MinesweeperBoard(int width, int height, int numMines)
        {
            Width = Math.Max(width, 1);
            Height = Math.Max(height, 1);
            _board = new Cell[Width + 2, Height + 2];
            NumMines = Math.Min(Math.Max(numMines, 0), Width * Height);
            
            _populateBoard();
        }

        private void _populateBoard()
        {
            var rand = new Random();
            var mineProbability = NumMines / ( Width * Height );
            var mined = new Cell[NumMines];
            var currNumMines = 0;
            for (var i = 0; i < Width; i++)
            {
                for (var j = 0; j < Height; j++)
                {
                    var index = i * Width + j;
                    if (index < NumMines)
                    {
                        var cell = new Cell(i, j, CellType.Mined);
                        this[i, j] = cell;
                        mined[currNumMines] = cell;
                        currNumMines++;
                        continue;
                    }
                    if (rand.NextDouble() < mineProbability)
                    {
                        //swap current cell into the list of mined cells
                        var select = rand.Next(mined.Length);
                        mined[select].Type = CellType.Safe;

                        var cell = new Cell(i, j, CellType.Mined);
                        mined[select] = cell;
                        this[i, j] = cell;
                    }
                    this[i, j] = new Cell(i, j, CellType.Safe);
                }
            }
        }

        public Cell this[int i, int j]{
            get { return _board[i + 1, j + 1]; }
            set { _board[i + 1, j + 1] = value; }
        }
    }
}