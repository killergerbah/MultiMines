using Microsoft.AspNet.SignalR;
using MultiMines.GameLogic;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;

namespace MultiMines.Hubs
{
    public class MinesweeperHub : Hub
    {
        //temporary; serve static board for testing purposes
        public static MinesweeperBoard Board = new MinesweeperBoard(30, 16, 99);

        public void GetBoard()
        {
            Clients.Caller.SetBoard(JsonConvert.SerializeObject(Board));
        }

        public void Uncover(int i, int j)
        {
            Board.Uncover(i, j);
            Clients.Others.Uncover(i, j);
        }

        public void ResetBoard()
        {
            Board = new MinesweeperBoard(30, 16, 99);
            Clients.All.Refresh();
        }

       /* public void BroadcastCursor(int i, int j)
        {
            Clients.Others.DrawCursor(i, j);
        }*/
    }
}