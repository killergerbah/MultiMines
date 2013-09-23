using Microsoft.AspNet.SignalR;
using MultiMines.GameLogic;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Timers;
using System.Web;
using WebMatrix.WebData;

namespace MultiMines.Hubs
{
    public class MinesweeperHub : Hub
    {
        static int GAME_WIDTH = 30;
        static int GAME_HEIGHT = 16;
        static int NUM_MINES = 99;
        //temporary; serve static board for testing purposes
        public static MinesweeperGame Game = new MinesweeperGame(GAME_WIDTH, GAME_HEIGHT, NUM_MINES);

        private static JsonSerializerSettings _jsonSettings = new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver() };

        private Broadcaster _broadcaster;

        public class Broadcaster
        {
            private readonly static Lazy<Broadcaster> _instance =
                new Lazy<Broadcaster>(() => new Broadcaster());
            private readonly double BroadcastInterval = 100;
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
                    _hubContext.Clients.All.Sync(JsonConvert.SerializeObject(MinesweeperHub.Game, _jsonSettings));
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
        
        public MinesweeperHub()
            : this(Broadcaster.Instance)
        {
        }

        public MinesweeperHub(Broadcaster broadcaster)
        {
            _broadcaster = broadcaster;
        }

        public void Join()
        {
            Clients.Caller.InitBoard(JsonConvert.SerializeObject(Game, _jsonSettings), WebSecurity.CurrentUserId);
        }

        public void Uncover(int i, int j, int userId, long eventId)
        {
            Game.Controller.OnUncover(new MinesweeperEventArgs(i, j, userId, eventId));
            Clients.All.Sync(JsonConvert.SerializeObject(Game, _jsonSettings));
        }

        public void Flag(int i, int j, int userId, long eventId)
        {
            Game.Controller.OnFlag(new MinesweeperEventArgs(i, j, userId, eventId));
            Clients.All.Sync(JsonConvert.SerializeObject(Game, _jsonSettings));
        }

        public void Unflag(int i, int j, int userId, long eventId)
        {
            Game.Controller.OnUnflag(new MinesweeperEventArgs(i, j, userId, eventId));
            Clients.All.Sync(JsonConvert.SerializeObject(Game, _jsonSettings));
        }

        public void SpecialUncover(int i, int j, int userId, long eventId)
        {
            Game.Controller.OnSpecialUncover(new MinesweeperEventArgs(i, j, userId, eventId));
            Clients.All.Sync(JsonConvert.SerializeObject(Game, _jsonSettings));
        }

        public void ResetBoard()
        {
            Game = new MinesweeperGame(GAME_WIDTH, GAME_HEIGHT, NUM_MINES);
            Clients.All.Refresh();
        }

        public void DisplayUserMouse(double x, double y, int userId)
        {
            Clients.Others.DisplayUserMouse(x, y, userId);
        }

        public void Penalize(int i, int j, int userId)
        {
            Clients.Others.Penalize(i, j, userId);
        }
    }
}