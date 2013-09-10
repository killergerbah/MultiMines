using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MultiMines.GameLogic;
using System.Diagnostics;

namespace MultiMinesTest
{
    [TestClass]
    public class GameLogicTests
    {
        [TestMethod]
        public void MinesweeperBoard_WithCorrectNumberOfMines_InitializesBoard()
        {
            int width = 50, height = 50, numMines = 100;
            Minesweeper game = new Minesweeper(width, height, numMines);
            var board = game.Board;
            var actualNumMines = 0;
            for (var i = 0; i < width; i++)
            {
                for (var j = 0; j < height; j++)
                {
                    if (board[i, j].Type == CellType.Mined)
                    {
                        actualNumMines++;
                    }
                }
            }
            Assert.AreEqual(numMines, actualNumMines, "Wrong number of mines");

        }

        [TestMethod]
        public void MinesweeperBoard_WholeBoardUncovered_WithNoMines()
        {
            int width = 50, height = 50;
            var board = new MinesweeperBoard(width, height, 0);
            for (var i = 0; i < width; i++)
            {
                for (var j = 0; j < height; j++)
                {
                    if (board[i, j].Status == CellStatus.Uncovered)
                    {
                        Assert.Fail("Board with no mines has invalid cell status");
                    }
                }
            }
        }

        [TestMethod]
        public void MinesweeperBoard_CascadesWholeBoard_WithNoMines()
        {
            int width = 50, height = 50;
            var board = new MinesweeperBoard(width, height, 0);
            board.Uncover(0, 0, 0);

            for (var i = 0; i < width; i++)
            {
                for (var j = 0; j < height; j++)
                {
                    if (board[i, j].Status == CellStatus.Covered)
                    {
                        Assert.Fail("Board with no mines has invalid cell status");
                    }
                }
            }
        }

        [TestMethod]
        public void MinesweeperBoard_CascadesAllButOne_WithOneMine()
        {
            int width = 50, height = 50;
            var board = new MinesweeperBoard(width, height, 0);
            board[0, 0].Type = CellType.Mined;
            board.Uncover(25, 25, 0);
            var cascaded = 0;
            for (var i = 0; i < width; i++)
            {
                for (var j = 0; j < height; j++)
                {
                    if (board[i, j].Status == CellStatus.Uncovered)
                        cascaded++;
                }
            }
            Assert.AreEqual(width * height - 1, cascaded, "Wrong number of cascaded cells");
        }


        [TestMethod]
        public void MinesweeperBoard_Clone_PerformsDeepCopy()
        {
            int width = 50, height = 50, numMines = 10;
            var board = new MinesweeperBoard(width, height, numMines);
            var clone = (MinesweeperBoard) board.Clone();
            Assert.AreNotSame(board, clone, "Clone cannot produce same object reference");
            for (var i = 0; i < height; i++)
            {
                for (var j = 0; j < width; j++)
                {
                    var original = board[i, j];
                    var copied = clone[i, j];
                    //Debug.WriteLine(original.Equals(copied) + " " + original.X + " " + original.Y + " " + original.Type + " " + original.Status + " " + copied.X + " " + copied.Y + " " + copied.Type + " " + copied.Status); 
                    Assert.IsTrue(board[i, j].Equals(clone[i, j]));
                    Assert.AreNotSame(board[i, j], clone[i, j], "Clone copied a cell object reference");
                }
            }
        }
    }
}
