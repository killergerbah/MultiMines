using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MultiMines.GameLogic
{
    public class MinesweeperEventJournal : IEnumerable<MinesweeperEvent>
    {
        private static TimeSpan EVENT_WINDOW = TimeSpan.FromMilliseconds(1000);
        private Queue<MinesweeperEvent> _journal;

        public MinesweeperEventJournal(MinesweeperController ms)
        {
            _journal = new Queue<MinesweeperEvent>();
            ms.Uncover += RecordUncover;
            ms.SpecialUncover += RecordSpecialUncover;
            ms.Flag += RecordFlag;
            ms.Unflag += RecordUnflag;
        }

        void RecordUncover(object sender, MinesweeperEventArgs e)
        {
            lock (_journal)
            {
                _journal.Enqueue(new MinesweeperEvent("uncover", e));
            }
        }

        void RecordSpecialUncover(object sender, MinesweeperEventArgs e)
        {
            lock (_journal)
            {
                _journal.Enqueue(new MinesweeperEvent("specialUncover", e));
            }
        }

        void RecordFlag(object sender, MinesweeperEventArgs e)
        {
            lock (_journal)
            {
                _journal.Enqueue(new MinesweeperEvent("flag", e));
            }
        }

        void RecordUnflag(object sender, MinesweeperEventArgs e)
        {
            lock (_journal)
            {
                _journal.Enqueue(new MinesweeperEvent("unflag", e));
            }
        }

        private void _prune()
        {
            lock (_journal)
            {
                while (_journal.Any())
                {
                    var e = _journal.Peek();
                    if (!e.IsOld(EVENT_WINDOW))
                    {
                        break;
                    }
                    _journal.Dequeue();
                }
            }
        }

        public IEnumerator<MinesweeperEvent> GetEnumerator()
        {
            _prune();
            return new MinesweeperEventJournalEnumerator(_journal);
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }
    }

    public class MinesweeperEventJournalEnumerator : IEnumerator<MinesweeperEvent>
    {
        private MinesweeperEvent[] _journal;
        int position = -1;
        public MinesweeperEventJournalEnumerator(Queue<MinesweeperEvent> journal)
        {
            _journal = journal.ToArray();
        }

        public bool MoveNext()
        {
            position++;
            return position < _journal.Length;
        }

        public void Reset()
        {
            position = -1;
        }

        object IEnumerator.Current
        {
            get
            {
                return Current;
            }
        }

        void IDisposable.Dispose() { }

        public MinesweeperEvent Current
        {
            get
            {
                try
                {
                    return _journal[position];
                }
                catch
                {
                    throw new InvalidOperationException();
                }
            }
        }
    }
}