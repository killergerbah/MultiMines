using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public abstract class GameState
    {
        public abstract bool Verify(object gameData);
    }
}