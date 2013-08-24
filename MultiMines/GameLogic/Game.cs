using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public abstract class Game
    {
        public long Id { get; set; }

        public abstract Player[] Players { get; private set; }

        public abstract Player Winner { get; private set; }

        public abstract GameState GameState { get; private set; }

        public abstract GameState Transition(Move move);
    }
}