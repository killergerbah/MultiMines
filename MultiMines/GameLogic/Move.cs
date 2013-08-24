using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public abstract class Move
    {
        public abstract Player Player { get; protected set; }

        public abstract GameState EndState { get; }

        public abstract GameState StartState { get; protected set; }
    }
}