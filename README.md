# fprint-demo

GTK+3 demo app for [libfprint]


## About

This is an update to the [original fprint_demo application][original]. It is
written in the [vala] programming language and is licensed under GPLv2 (see
[LICENSE]).

It is still in the early stages of development, so not much works yet.


## Hacking

Pull requests welcome. This should get you started:

    sudo apt-get install cmake valac libfprint-dev libgtk-3-dev
    git clone --recursive https://github.com/dlech/fprint-demo
    mkdir build-dir
    cd build-dir
    cmake ../fprint-demo -DCMAKE_BUILD_TYPE=Debug
    make
    ./fprint-demo


[libfprint]: https://www.freedesktop.org/wiki/Software/fprint/libfprint/
[original]: https://www.freedesktop.org/wiki/Software/fprint/fprint_demo/
[vala]: https://wiki.gnome.org/Projects/Vala
[LICENSE]: ./LICENSE
