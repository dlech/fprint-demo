
[CCode (cheader_filename = "fprint.h")]
namespace Fp {
    public static int init ();
    public static void exit ();
    public static void set_debug (int level);

    [CCode (cname = "enum fp_capture_result", cprefix = "FP_CAPTURE_", has_type_id = false)]
    public enum CaptureResult {
        COMPLETE,
        FAIL,
    }

    [CCode (cname = "enum fp_enroll_result", cprefix = "FP_ENROLL_", has_type_id = false)]
    public enum EnrollResult {
        COMPLETE,
        FAIL,
        PASS,
        RETRY,
        RETRY_TOO_SHORT,
        RETRY_CENTER_FINGER,
        RETRY_REMOVE_FINGER,
    }

    [CCode (cname = "enum fp_verify_result", cprefix = "FP_VERIFY_", has_type_id = false)]
    public enum VerifyResult {
        NO_MATCH,
        MATCH,
        RETRY,
        RETRY_TOO_SHORT,
        RETRY_CENTER_FINGER,
        RETRY_REMOVE_FINGER,
    }

    [CCode (cname = "struct fp_dev", has_type_id = false)]
    [Compact]
    public class Dev {
        public static unowned Dev? open (DscvDev ddev);
        public void close ();

        [CCode (cname = "fp_dev_open_cb", has_type_id = false)]
        public delegate void OpenCallback(Dev? dev, int status);
        [CCode (cname = "fp_async_dev_open")]
        public static int open_async (DscvDev ddev, OpenCallback callback);

        [CCode (cname = "fp_dev_close_cb", has_type_id = false)]
        public delegate void CloseCallback(Dev dev);
        [CCode (cname = "fp_async_dev_close")]
        public void close_async (CloseCallback callback);

        public unowned Driver driver { get; }
        public int nr_enroll_stages { get; }
        public uint32 devtype { get; }
        public bool supports_print_data (PrintData data);
        public bool supports_dscv_print (DscvPrint data);
        public bool supports_imaging ();
        public bool supports_identification ();
        public int img_capture (bool unconditional, ref Img image);
        public int img_width { get; }
        public int img_height { get; }
        [CCode (cname = "fp_enroll_finger_img")]
        public int enroll_finger (out PrintData print_data, out Img? img = null);
        [CCode (cname = "fp_verify_finger_img")]
        public int verify_finger (PrintData enrolled_print, out Img? img = null);
        [CCode (cname = "fp_identify_finger_img")]
        public int identify_finger ([CCode (array_null_terminated = true)] PrintData[] print_gallery, out size_t match_offset, out Img? img = null);

        [CCode (cname = "fp_enroll_stage_cb")]
        public delegate void EnrollStageCallback(Dev dev, int result, owned PrintData? print, owned Img? img);
        [CCode (cname = "fp_async_enroll_start")]
        public int enroll_start (EnrollStageCallback callback);
        [CCode (cname = "fp_enroll_stop_cb")]
        public delegate void EnrollStopCallback(Dev dev);
        [CCode (cname = "fp_async_enroll_stop")]
        public int enroll_stop (EnrollStopCallback callback);
    }

    [CCode (cname = "struct fp_dscv_dev *", free_function = "fp_dscv_devs_free", has_type_id = false)]
    [Compact]
    public class DscvDevArray {
        [CCode (cname = "fp_dscv_dev_for_print_data")]
        public unowned DscvDev dev_for_print_data(PrintData data);
        [CCode (cname = "fp_dscv_dev_for_dscv_print")]
        public unowned DscvDev dev_for_dscv_print(DscvPrint data);

        public void foreach (GLib.Func<DscvDev> func) {
            for (var ptr = (void **)this; ptr[0] != null; ptr++) {
                func((DscvDev)ptr[0]);
            }
        }
    }

    [CCode (cname = "struct fp_dscv_dev", has_type_id = false)]
    [Compact]
    public class DscvDev {
        [CCode (cname = "fp_discover_devs")]
        public static DscvDevArray discover ();

        public unowned Driver driver { get; }
        public uint32 devtype { get; }
        public bool supports_print_data (PrintData data);
        public bool supports_dscv_print (DscvPrint data);
    }

    [CCode (cname = "struct fp_driver", has_type_id = false)]
    [Compact]
    public class Driver {
        public unowned string name { get; }
        public unowned string full_name { get; }
        public uint16 driver_id { get; }
        public ScanType scan_type { get; }
    }

    [CCode (cname = "enum fp_finger", has_type_id = false)]
    public enum Finger {
        [CCode (cname = "LEFT_THUMB")]
        LEFT_THUMB,
        [CCode (cname = "LEFT_INDEX")]
        LEFT_INDEX,
        [CCode (cname = "LEFT_MIDDLE")]
        LEFT_MIDDLE,
        [CCode (cname = "LEFT_RING")]
        LEFT_RING,
        [CCode (cname = "LEFT_LITTLE")]
        LEFT_LITTLE,
        [CCode (cname = "RIGHT_THUMB")]
        RIGHT_THUMB,
        [CCode (cname = "RIGHT_INDEX")]
        RIGHT_INDEX,
        [CCode (cname = "RIGHT_MIDDLE")]
        RIGHT_MIDDLE,
        [CCode (cname = "RIGHT_RING")]
        RIGHT_RING,
        [CCode (cname = "RIGHT_LITTLE")]
        RIGHT_LITTLE,
    }

    [CCode (cname = "enum fp_scan_type", has_type_id = false)]
    public enum ScanType {
        PRESS,
        SWIPE,
    }

    [CCode (cname = "struct fp_print_data", free_function = "fp_print_data_free", has_type_id = false)]
    [Compact]
    public class PrintData {
        size_t get_data ([CCode (array_length = false)] out uint8[] ret);
        public uint8[] data {
            [CCode (cname = "vala_fp_print_data_get_data")]
            owned get {
                uint8[] ret;
                var size = get_data (out ret);
                ret.length = (int)size;
                return (owned)ret;
            }
        }
        public static PrintData? from_data (uint8[] buf);
        public int save (Finger finger);
        public static int load (Dev dev, Finger finger, out PrintData data);
        public static int delete (Dev dev, Finger finger);
        public static int from_dscv_print(DscvPrint print, out PrintData data);
        public uint16 driver_id { get; }
        public uint32 devtype { get; }
    }

    [CCode (cname = "struct fp_dscv_print *", free_function = "fp_dscv_prints_free", has_type_id = false)]
    [Compact]
    public class DscvPrintArray {
        public void foreach (GLib.Func<DscvPrint> func) {
            for (var ptr = (void **)this; ptr[0] != null; ptr++) {
                func((DscvPrint)ptr[0]);
            }
        }
    }

    [CCode (cname = "struct fp_dscv_print", has_type_id = false)]
    [Compact]
    public class DscvPrint {
        [CCode (cname = "fp_discover_prints")]
        public static DscvPrintArray discover ();
        public uint16 driver_id { get; }
        public uint32 devtype { get; }
        public Finger finger { get; }
        public int delete ();
    }

    [CCode (cname = "struct fp_img", free_function = "fp_img_free", has_type_id = false)]
    [Compact]
    public class Img {
        public int height { get; }
        public int width { get; }
        [CCode (array_length = false)]
        unowned uint8[] get_data ();
        public unowned uint8[] data {
            [CCode (cname = "vala_fp_img_get_data")]
            get {
                unowned uint8[] ret = get_data ();
                ret.length = width * height;
                return ret;
            }
        }
        public int save_to_file (string path);
        public void standarize ();
        public Img binarize ();
        public unowned Minutia[] minutiae { get; }
    }

    [CCode (cname = "struct fp_minutia", has_type_id = false)]
    [Compact]
    public class Minutia {
        public int x;
        public int y;
        public int ex;
        public int ey;
        public int direction;
        public double reliability;
        public int type;
        public int appearing;
        public int feature_id;
        [CCode (array_length_cname = "num_nbrs")]
        public int[] nbrs;
        [CCode (array_length_cname = "num_nbrs")]
        public int[] ridge_counts;
    }

    [CCode (cname = "struct fp_pollfd", free_function = "g_free", has_type_id = false)]
    public struct Pollfd {
        public int fd;
        public short events;
    }

    public bool handle_events_timeout (ref Posix.timeval timeout);
    public bool handle_events ();

    [CCode (cname = "fp_get_pollfds")]
    public size_t _get_pollfds ([CCode (array_length = false)] out Pollfd[] pollfds);
    [CCode (cname = "vala_fp_get_pollfds")]
    public Pollfd[] get_pollfds () {
        Pollfd[] pollfds;
        var size = _get_pollfds (out pollfds);
        pollfds.length = (int)size;

        return (owned)pollfds;
    }

    public bool get_next_timeout (out Posix.timeval tv);

    [CCode (cname = "fp_pollfd_added_cb", has_target = false, has_type_id = false)]
    public delegate void PollfdAddedCallback (int fd, short events);
    [CCode (cname = "fp_pollfd_removed_cb", has_target = false, has_type_id = false)]
    public delegate void PollfdRemovedCallback (int fd);
    public void set_pollfd_notifiers (PollfdAddedCallback added_cb, PollfdRemovedCallback remove_cb);
}
