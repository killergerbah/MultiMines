using Microsoft.AspNet.SignalR;
using MultiMines.GameLogic;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Timers;
using System.Web;
using WebMatrix.WebData;

namespace MultiMines.Hubs
{
    public class Broadcaster
    {
        private readonly static Lazy<Broadcaster> _instance =
            new Lazy<Broadcaster>(() => new Broadcaster());
        private readonly double BroadcastInterval = 40;
        private readonly IHubContext _hubContext;
        private Timer _broadcastLoop;
        private bool _stateChanged = true;
            
        public Broadcaster()
        {
            _hubContext = GlobalHost.ConnectionManager.GetHubContext<MinesweeperHub>();

            _broadcastLoop = new Timer(BroadcastInterval);
            _broadcastLoop.Elapsed += BroadcastState;
            _broadcastLoop.Start();
        }

        public void BroadcastState(object source, ElapsedEventArgs e)
        {
            if (_stateChanged)
            {
                _hubContext.Clients.All.Sync(JsonConvert.SerializeObject(MinesweeperHub.Game.Board));
            }
            _stateChanged = false;
        }

        public void UpdateState()
        {
            _stateChanged = true;
        }

        public static Broadcaster Instance
        {
            get
            {
                return _instance.Value;
            }
        }
    }

    public class MinesweeperHub : Hub
    {
        
        //temporary; serve static board for testing purposes
        public static Minesweeper Game = new Minesweeper(30, 16, 99);

        private Broadcaster _broadcaster;

        public MinesweeperHub()
            : this(Broadcaster.Instance)
        {
        }

        public MinesweeperHub(Broadcaster broadcaster)
        {
            _broadcaster = broadcaster;
        }

        public void GetBoard()
        {
            Clients.Caller.SetBoard(JsonConvert.SerializeObject(Game.Board));
        }

        public void Uncover(int i, int j)
        {
            Game.Uncover(i, j);
            _broadcaster.UpdateState();
            //Clients.Others.Uncover(i, j);
        }

        public void ResetBoard()
        {
            Game = new Minesweeper(30, 16, 99);
            Clients.All.Refresh();
        }

        public void DisplayUserCursor(int i, int j, int userId)
        {
            Clients.Others.DisplayUserCursor(i, j, userId);
        }

        public void GetMyUserId()
        {
            Clients.Caller.SetMyUserId(WebSecurity.CurrentUserId);
        }
    }
}