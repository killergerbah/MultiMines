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

        public MinesweeperEvent(string callBackKey, MinesweeperEventArgs e)
        {
            CallbackKey = callBackKey;
            Args = new List<int> { e.X, e.Y, e.UserId };
            Id = e.EventId;
            Timestamp = DateTimeOffset.Now;
        }


        public bool IsOld(TimeSpan window)
        {
            return DateTimeOffset.Compare(DateTimeOffset.Now.Subtract(window), Timestamp) > 0;
        }
    }
}