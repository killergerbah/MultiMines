using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Web;

namespace MultiMines.GameLogic
{
    [DataContract]
    public class Minesweeper
    {
        public static TimeSpan EVENT_WINDOW = TimeSpan.FromMilliseconds(500);

        [DataMember]
        public MinesweeperBoard Board { get; private set; }

        [DataMember]
        public Queue<MinesweeperEvent> EventJournal
        {
            get
            {
                _pruneJournal();
                return _eventJournal;
            }

            private set
            {
                _eventJournal = value;
            }
        }

        private Queue<MinesweeperEvent> _eventJournal; 

        public Minesweeper(int width, int height, int numMines) 
        {
            Board = new MinesweeperBoard(width, height, numMines);
            _eventJournal = new Queue<MinesweeperEvent>();
        }

        public void Uncover(int i, int j, int userId, long eventId)
        {
            Board.Uncover(i, j, userId);
            _recordEvent(Board.Uncover, i, j, userId, eventId);
        }


        public void Flag(int i, int j, int userId, long eventId)
        {
            Board.Flag(i, j, userId);
            _recordEvent(Board.Flag, i, j, userId, eventId);
        }

        public void Unflag(int i, int j, int userId, long eventId)
        {
            Board.Unflag(i, j, userId);
            _recordEvent(Board.Unflag, i, j, userId, eventId);
        }

        public void SpecialUncover(int i, int j, int userId, long eventId)
        {
            Board.SpecialUncover(i, j, userId);
            _recordEvent(Board.SpecialUncover, i, j, userId, eventId);
        }

        private void _pruneJournal()
        {
            lock (_eventJournal)
            {
                while (_eventJournal.Any())
                {
                    var e = _eventJournal.Peek();
                    if (!e.IsOld(EVENT_WINDOW))
                    {
                        break;
                    }
                    _eventJournal.Dequeue();
                }
            }
        }

        private void _recordEvent(Action<int, int, int> action, int arg1, int arg2, int arg3, long eventId)
        {
            lock (_eventJournal)
            {
                _eventJournal.Enqueue(new MinesweeperEvent(action, arg1, arg2, arg3, eventId));
            }
        }
    }
}