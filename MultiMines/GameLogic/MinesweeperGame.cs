using System;
using System.Collections.Generic;
using System.Linq;
using System.Timers;
using System.Web;

namespace MultiMines.GameLogic
{
    public class MinesweeperGame
    {
        public MinesweeperEventJournal EventJournal { get; private set; }
        public MinesweeperController Controller { get; private set; }

        public Dictionary<int, int> Scores { get; private set; }
        public double TimeElapsed
        {
            get
            {
                return DateTime.Now.Subtract(_createdAt).TotalMilliseconds;
            }
        }
        private DateTime _createdAt;

        public MinesweeperGame(int width, int height, int numMines)
        {
            Controller = new MinesweeperController(width, height, numMines);
            EventJournal = new MinesweeperEventJournal(Controller);
            Scores = new Dictionary<int, int>();
            Controller.Flag += HandleFlag;
            Controller.Unflag += HandleUnflag;
            Controller.Uncover += HandleUncover;
            Controller.SpecialUncover += HandleSpecialUncover;

            _createdAt = DateTime.Now;
        }

        protected virtual void HandleFlag(object sender, MinesweeperEventArgs e)
        {
            var userId = e.UserId;
            if(!Scores.ContainsKey(userId))
            {
                Scores[userId] = 0;
            }
            Scores[userId]++;
        }

        protected virtual void HandleUnflag(object sender, MinesweeperEventArgs e)
        {
            var userId = e.UserId;
            if (!Scores.ContainsKey(userId))
            {
                //shouldn't happen
                Scores[userId] = 0;
            }
            Scores[userId]--;
        }

        protected virtual void HandleUncover(object sender, MinesweeperEventArgs e)
        {

        }

        protected virtual void HandleSpecialUncover(object sender, MinesweeperEventArgs e)
        {

        }
    }
}