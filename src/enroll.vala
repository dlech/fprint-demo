
using Fp;
using Gtk;

namespace FprintDemo {
    public class EnrollWidget : Gtk.Grid {
        struct RowData {
            public string desc;
            public Finger finger;
        }

        static RowData[] rows = new RowData[10] {
            RowData () { desc = "Left Little", finger = Finger.LEFT_LITTLE },
            RowData () { desc = "Left Ring", finger = Finger.LEFT_RING },
            RowData () { desc = "Left Middle", finger = Finger.LEFT_MIDDLE },
            RowData () { desc = "Left Index", finger = Finger.LEFT_INDEX },
            RowData () { desc = "Left Thumb", finger = Finger.LEFT_THUMB },
            RowData () { desc = "Right Thumb", finger = Finger.RIGHT_THUMB },
            RowData () { desc = "Right Index", finger = Finger.RIGHT_INDEX },
            RowData () { desc = "Right Middle", finger = Finger.RIGHT_MIDDLE },
            RowData () { desc = "Right Ring", finger = Finger.RIGHT_RING },
            RowData () { desc = "Right Little", finger = Finger.RIGHT_LITTLE },
        };

        struct RowWidgets {
            public Label status_label;
            public Button enroll_button;
            public Button delete_button;
        }
        HashTable<Finger, RowWidgets?> row_map = new HashTable<Finger, RowWidgets?> (direct_hash, direct_equal);
        HashTable<Finger, unowned DscvPrint?> print_map = new HashTable<Finger, unowned DscvPrint?> (direct_hash, direct_equal);

        public EnrollWidget () {
            column_homogeneous = true;
            row_homogeneous = true;
            column_spacing = 6;
            row_spacing = 6;
            margin = 12;

            attach (new Label ("<b>Finger</b>") { use_markup = true }, 0, 0);
            attach (new Label ("<b>Status</b>") { use_markup = true }, 1, 0);
            attach (new Label ("<b>Action</b>") { use_markup = true }, 2, 0, 2, 1);

            for (int r = 0; r < rows.length; r++) {
                var finger = rows[r].finger;
                var rw = RowWidgets ();

                attach (new Label (rows[r].desc), 0, r + 1);

                rw.status_label = new Label ("<unknown>");
                attach (rw.status_label, 1, r + 1);

                rw.enroll_button = new Button.with_label ("Enroll");
                rw.enroll_button.clicked.connect (() => enroll (finger));
                attach (rw.enroll_button, 2, r + 1);

                rw.delete_button = new Button.with_label ("Delete");
                rw.delete_button.clicked.connect (() => delete (print_map[finger]));
                attach (rw.delete_button, 3, r + 1);

                row_map[finger] = rw;
            }
        }

        public void set_finger_print (Finger finger, DscvPrint? print) {
            var rw = row_map[finger];
            print_map[finger] = print;
            var present = print != null;
            rw.status_label.label = present ? "Enrolled" : "Not enrolled";
            rw.delete_button.sensitive = present;
        }

        public void clear_finger_prints () {
            foreach (var f in row_map.get_keys ()) {
                set_finger_print (f, null);
            }
        }

        public signal void enroll (Finger finger);

        public signal void delete (DscvPrint print);
    }
}
