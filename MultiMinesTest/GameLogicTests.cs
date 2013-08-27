using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MultiMines.GameLogic;

namespace MultiMinesTest
{
    [TestClass]
    public class GameLogicTests
    {
        [TestMethod]
        public void MinesweeperBoard_WithCorrectNumberOfMines_InitializesBoard()
        {
            int width = 50, height = 50, numMines = 100;
            Player p1 = new Player(1, "p1");
            Player p2 = new Player(2, "p2");
            Player[] players = new Player[] { p1, p2 };
            Minesweeper game = new Minesweeper(1, width, height, numMines, players);
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
                    if (board[i, j].Status != CellStatus.Unflagged || board[i, j].Status == CellStatus.Flagged)
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
            board.Uncover(0, 0);

            for (var i = 0; i < width; i++)
            {
                for (var j = 0; j < height; j++)
                {
                    if (board[i, j].Status == CellStatus.Unflagged || board[i, j].Status == CellStatus.Flagged)
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
            var board = new MinesweeperBoard(width, height, 1);
            board.Uncover(25, 25);
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
    }
}
