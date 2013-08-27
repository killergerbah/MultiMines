using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public interface IGame<S, M> where S : IEquatable<S>
    {
        S State { get; }
        S Transition(M move);
    }
}