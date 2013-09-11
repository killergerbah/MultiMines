using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Web;

namespace MultiMines.GameLogic
{
    [DataContract]
    public class MinesweeperEvent
    {
        [DataMember]
        public string CallbackKey { get; private set; }

        [DataMember]
        public List<int> Args { get; private set; }

        [DataMember]
        public long Id { get; private set; }

        public DateTimeOffset Timestamp { get; private set; }

        public MinesweeperEvent(Action<int, int, int> action, int arg1, int arg2, int arg3, long id)
        {
            CallbackKey = action.Method.Name;
            Args = new List<int> { arg1, arg2 };
            Timestamp = DateTimeOffset.Now;
            Id = id;
        }


        public bool IsOld(TimeSpan window)
        {
            return DateTimeOffset.Compare(DateTimeOffset.Now.Subtract(window), Timestamp) > 0;
        }
    }
}