
using Fp;
using Gtk;

namespace FprintDemo {

    public class App : Gtk.Application {
        ApplicationWindow window;
        DscvDevArray devices;
        DscvPrintArray prints;
        unowned Dev active_device;
        Gtk.ListStore device_store;
        ComboBox device_picker;
        EnrollWidget enroll_widget;
        Statusbar status_bar;

        enum StatusbarContext {
            OPEN,
            CLOSE,
            ENROLL,
        }

        public App () {
            Object(application_id: "org.dlech.fprint-demo",
                    flags: ApplicationFlags.FLAGS_NONE);
        }

        protected override void activate () {

            devices = DscvDev.discover ();

            // Create the window of this application and show it
            window = new ApplicationWindow (this);
            window.set_default_size (800, 600);
            window.title = "fprint demo";
            window.window_position = WindowPosition.CENTER;
            window.destroy.connect (() => {
                if (active_device != null) {
                    active_device.close ();
                }
                devices = null;
            });

            status_bar = new Statusbar ();

            device_store = new Gtk.ListStore (2, typeof(void *), typeof(string));
            devices.foreach ((dev) => {
                TreeIter iter;
                device_store.append (out iter);
                device_store.set (iter, 0, dev);
                device_store.set (iter, 1, dev.driver.full_name);
            });

            device_picker = new ComboBox.with_model (device_store);

            var renderer = new CellRendererText ();
            device_picker.pack_start (renderer, true);
            device_picker.add_attribute (renderer, "text", 1);
            device_picker.changed.connect (on_device_picker_changed);
            device_picker.active = 0;

            var tabs = new Notebook ();

            enroll_widget = new EnrollWidget ();
            enroll_widget.sensitive = false;
            enroll_widget.enroll.connect (on_enroll);
            enroll_widget.delete.connect (on_delete);
            tabs.append_page (enroll_widget);
            tabs.set_tab_label_text (enroll_widget, "Enroll");
            var page2 = new Label ("page 2");
            tabs.append_page (page2);
            tabs.set_tab_label_text (page2, "Verify");
            var page3 = new Label ("page 3");
            tabs.append_page (page3);
            tabs.set_tab_label_text (page3, "Identify");
            var page4 = new Label ("page 4");
            tabs.append_page (page4);
            tabs.set_tab_label_text (page4, "Capture");

            var inner_box = new Box (Orientation.VERTICAL, 6);
            inner_box.margin = 12;
            inner_box.margin_bottom = 0;
            inner_box.pack_start (device_picker, false);
            inner_box.pack_end (tabs);

            var outer_box = new Box (Orientation.VERTICAL, 0);
            outer_box.pack_start (inner_box);
            outer_box.pack_end (status_bar, false);
            window.add (outer_box);

            window.show_all ();
        }

        void refresh_prints () {
            enroll_widget.clear_finger_prints ();
            prints = DscvPrint.discover ();
            prints.foreach ((p) => {
                if (active_device.supports_dscv_print (p)) {
                    enroll_widget.set_finger_print (p.finger, p);
                }
            });
        }

        async void do_change_device (DscvDev new_dev) {
            if (active_device != null) {
                enroll_widget.sensitive = false;
                status_bar.push (StatusbarContext.CLOSE, "Closing %s ...".printf (active_device.driver.full_name));
                yield close_async (active_device);
                status_bar.pop (StatusbarContext.CLOSE);
                active_device = null;
            }

            unowned Dev d;
            status_bar.push (StatusbarContext.OPEN, "Opening %s ...".printf (new_dev.driver.full_name));
            var ret = yield open_async (new_dev, out d);
            status_bar.pop (StatusbarContext.OPEN);
            if (ret < 0) {
                // TODO: the error codes returned are a mix of libusb errors
                // and posix errors, so it is difficult to report a decent
                // error message.
                var dialog = new MessageDialog (window, DialogFlags.MODAL, MessageType.ERROR, ButtonsType.CLOSE,
                    "Failed to open device: %d", ret);
                weak MessageDialog weak_dialog = dialog;
                dialog.response.connect (() => weak_dialog.destroy ());
                dialog.run ();
            } else {
                enroll_widget.sensitive = true;
                active_device = d;
                refresh_prints ();
            }
        }

        void on_device_picker_changed () {
            TreeIter iter;
            Value val;

            if (!device_picker.get_active_iter (out iter)) {
                return;
            }

            device_store.get_value (iter, 0, out val);

            do_change_device.begin ((DscvDev)val, (obj, res) => {
                do_change_device.end (res);
            });
        }

        async void do_enroll (Finger finger, EnrollProgressFunc progress, Cancellable cancellable) throws IOError {
            status_bar.push (StatusbarContext.ENROLL, "Enrolling...");
            try {
                var ret = yield enroll_async (active_device, progress, cancellable);
                if (ret < 0) {
                    message ("error: %d", ret);
                    return;
                }
            } finally {
                status_bar.pop (StatusbarContext.ENROLL);
            }
        }

        EnrollProgressFunc on_enroll_progress (MessageDialog dialog, Finger finger) {
            EnrollProgressFunc func = (s, p, i) => {
                dialog.secondary_text = s.to_string ();
                if (s == EnrollResult.COMPLETE) {
                    p.save (finger);
                    refresh_prints ();
                }
            };
            return (owned)func;
        }

        void on_enroll (Finger finger) {
            var dialog = new MessageDialog (window, DialogFlags.MODAL, MessageType.INFO, ButtonsType.CANCEL,
                "Enrollment");
            var cancellable = new Cancellable ();
            dialog.response.connect ((d, r) => {
                cancellable.cancel ();
            });
            var progress = on_enroll_progress (dialog, finger);
            do_enroll.begin (finger, progress, cancellable, (obj, res) => {
                try {
                    do_enroll.end (res);
                } catch (IOError err) {
                    // canceled
                }
                dialog.destroy ();
            });
            dialog.run ();
        }

        void on_delete (DscvPrint print) {
            var ret = print.delete ();
            if (ret < 0) {
                var dialog = new MessageDialog (window, DialogFlags.MODAL, MessageType.ERROR, ButtonsType.CLOSE,
                    "Failed to delete print: %d", ret);
                dialog.run ();
            } else {
                refresh_prints ();
            }
        }

        public static int main (string[] args) {
            var ret = Fp.init ();
            if (ret < 0) {
                error ("Failed to init libfprint: %d", ret);
            }
            Fp.Source.add ();
            App app = new App ();
            ret = app.run (args);

            Fp.exit ();

            return ret;
        }
    }
}
