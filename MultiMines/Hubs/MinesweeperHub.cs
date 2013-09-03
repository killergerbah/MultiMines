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
        public static int numConnected = 0;
        public override Task OnConnected()
        {
            if (numConnected == 0)
            {
                Board = new MinesweeperBoard(30, 16, 99);
            }
            numConnected++;
            return base.OnConnected();
        }

        public override Task OnDisconnected()
        {
            numConnected--;
            return base.OnDisconnected();
        }

        public void GetBoard()
        {
            Clients.Caller.SetBoard(JsonConvert.SerializeObject(Board));
        }

        public void Uncover(int i, int j)
        {
            Board.Uncover(i, j);
            Clients.Others.uncover(i, j);
        }
    }
}