using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines
{
    public class MinesweeperBoard 
    {
        private Cell[,] _board;

        public int Width { get; private set; }

        public int Height { get; private set; }

        public int NumMines { get; private set; }

        public MinesweeperBoard(int width, int height, int numMines)
        {
            _board = new Cell[width, height];
            NumMines = Math.Min(Math.Max(numMines, 0), width * height);
            Width = width;
            Height = height;
            _populateBoard();
        }

        public MinesweeperBoard(Cell[,] board){
            Width = board.GetLength(0);
            Height = board.GetLength(1);
            var numMines = 0;
            for(var i = 0; i < Width; i++)
            {
                for(var j = 0; j < Height; j++)
                {
                    if(board[i, j].Type == CellType.Mined)
                    {
                        numMines++;
                    }
                }
            }
            NumMines = numMines;
            _board = board;
        }

        public MinesweeperBoard Copy(){
            var _boardCopy = new Cell[Width, Height];
            for(int i = 0; i < Width; i++)
            {
                for (int j = 0; j < Height; j++)
                {
                    _boardCopy[i, j] = new Cell(_board[i, j].Type);
                }
            }
            return new MinesweeperBoard(_boardCopy);
        }

        private void _populateBoard()
        {
            var _rand = new Random();
            var _mineProbability = NumMines / ( Width * Height );
            for (var i = 0; i < Width; i++)
            {
                for (var j = 0; j < Height; j++)
                {
                    var index = i * Width + j;
                    if (index < NumMines)
                    {
                        _board[i, j] = new Cell(CellType.Mined);
                        continue;
                    }
                    var _random = _rand.NextDouble();
                    if (_random < _mineProbability)
                    {
                        var randomSelect = (int)Math.Floor((_random / _mineProbability) * NumMines);
                        _board[randomSelect / i, randomSelect % i].Type = CellType.Safe;
                        _board[i, j].Type = CellType.Mined;
                    }
                }
            }
        }
    }
}