
// TODO: It would be nice to have these functions in libprintf.vapi but there
// seems to be a vala compiler bug that prevents them from working correctly
// when declared in a vapi.

namespace Fp {
    public static async int open_async (DscvDev ddev, out unowned Dev dev) {
        unowned Dev device = null;
        int status = 0;
        bool async_callback = false;
        bool callback_done = false;
        var ret = Dev.open_async (ddev, (d, s) => {
            device = d;
            status = s;

            // This lambda function may be called before _open_async() returns.
            // In that case, we must not call open_async.callback() or it
            // will break stuff.
            if (async_callback) {
                open_async.callback ();
            }
            callback_done = true;
        });
        if (ret < 0) {
            dev = null;
            return ret;
        }

        // _open_async can complete synchronously, so only yield if we are
        // really doing this async.
        if (!callback_done) {
            async_callback = true;
            yield;
        }

        dev = device;

        return status;
    }

    public static async void close_async (Dev dev) {
        bool async_callback = false;
        bool callback_done = false;
        dev.close_async ((d) => {
            // This lambda function may be called before _close_async() returns.
            // In that case, we must not call close_async.callback() or it
            // will break stuff.
            if (async_callback) {
                close_async.callback ();
            }
            callback_done = true;
        });

        // _close_async can complete synchronously, so only yield if we are
        // really doing this async.
        if (!callback_done) {
            async_callback = true;
            yield;
        }
    }

    public delegate void EnrollProgressFunc (EnrollResult result, owned PrintData? data, owned Img? img);

    // TODO: libfprint errors should throw instead of returning int
    public static async int enroll_async (Dev dev, owned EnrollProgressFunc? progress, Cancellable? cancellable) throws IOError {
        cancellable.set_error_if_cancelled ();
        int cb_result = 0;
        PrintData? cb_print_data = null;
        Img? cb_img = null;
        var ret = dev.enroll_start ((d, r, p, i) => {
            cb_result = r;
            cb_print_data = (owned)p;
            cb_img = (owned)i;
            if (!cancellable.is_cancelled ()) {
                enroll_async.callback ();
            }
        });
        if (ret < 0) {
            return ret;
        }
        ulong id = 0;
        if (cancellable != null) {
            // if we don't use Idle.add(), we get a deadlock because cancellable.is_cancelled()
            // after the yield is called while we are still in the signal handler, which holds
            // a mutex on the cancellable object.
            id = cancellable.connect ((c) => Idle.add (() => enroll_async.callback ()));
        }
        do {
            yield;
            if (cancellable.is_cancelled ()) {
                break;
            }
            if (cb_result < 0) {
                return cb_result;
            }
            if (progress != null) {
                progress ((EnrollResult)cb_result, (owned)cb_print_data, (owned)cb_img);
            }
        } while (cb_result != EnrollResult.COMPLETE && cb_result != EnrollResult.FAIL);

        cancellable.disconnect (id);

        ret = dev.enroll_stop ((d) => {
            enroll_async.callback ();
        });
        if (ret < 0) {
            return ret;
        }

        yield;

        cancellable.set_error_if_cancelled ();

        return 0;
    }
}
