
using Posix;

namespace Fp {
    public class Source : GLib.Source {
        static Fp.Source instance;
        static Array<PollFD?> pollfd_list;

        // have to make this a singleton since libfprint callbacks do not have
        // user data.
        public static Fp.Source get_instance () {
            if (instance == null) {
                instance = new Fp.Source ();
            }

            return instance;
        }

        public static uint add () {
            return get_instance ().attach (null);
        }

        Source () {
            pollfd_list = new Array<PollFD?> ();
            // setting instance here so we can call on_added () before returning
            instance = this;

            set_pollfd_notifiers (on_added, on_removed);
            var pollfds = get_pollfds ();
            foreach (var p in pollfds) {
                on_added (p.fd, p.events);
            }
        }

        protected override bool prepare (out int timeout) {
            timeval tv;
            if (!get_next_timeout (out tv)) {
                timeout = -1;
                return false;
            }

            if (tv.tv_sec == 0 && tv.tv_usec == 0) {
                timeout = -1;
                return true;
            }

            timeout = (int)(tv.tv_sec / 1000 + tv.tv_usec * 1000);

            return false;
        }

        protected override bool check () {
            foreach (var p in pollfd_list.data) {
                if (p.revents != 0) {
                    return true;
                }
            }

            timeval tv;
            if (!get_next_timeout (out tv)) {
                return false;
            }

            if (tv.tv_sec == 0 && tv.tv_usec == 0) {
                return true;
            }

            return false;
        }

        protected override bool dispatch (SourceFunc callback) {
            var tv = timeval (); // zero
            handle_events_timeout (ref tv);
            return true;
        }

        static void on_added (int fd, short events) {
            // have to convert libfprint (posix) pollfd to glib pollfd
            IOCondition e = 0;
            if ((events & POLLIN) == POLLIN) {
                e |= IOCondition.IN;
            }
            if ((events & POLLPRI) == POLLPRI) {
                e |= IOCondition.PRI;
            }
            if ((events & POLLOUT) == POLLOUT) {
                e |= IOCondition.OUT;
            }
            var p = PollFD () { fd = fd, events = e};
            pollfd_list.append_val (p);
            instance.add_poll (ref pollfd_list.data[pollfd_list.length - 1]);
        }

        static void on_removed (int fd) {
            for (int i = 0; i < pollfd_list.length; i++) {
                var p = pollfd_list.data[i];
                if (p.fd == fd) {
                    instance.remove_poll (ref p);
                    pollfd_list.remove_index_fast (i);
                    return;
                }
            }
            critical ("Could not find match");
        }
    }
}
