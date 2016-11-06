project("fprint-demo" C)

cmake_minimum_required(VERSION 2.6)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

find_package(PkgConfig REQUIRED)
pkg_check_modules(DEPS REQUIRED
    glib-2.0
    gobject-2.0
    gtk+-3.0
    libfprint
)

find_package(Vala REQUIRED)
include(ValaPrecompile)

vala_precompile(VALA_C ${PROJECT_NAME}
    src/app.vala
    src/enroll.vala
    src/fp_async.vala
    src/fp_source.vala
PACKAGES
    glib-2.0
    gobject-2.0
    gtk+-3.0
    posix
CUSTOM_VAPIS
    vapi/*.vapi
OPTIONS
    --target-glib=2.40
    --thread
)

add_executable(${PROJECT_NAME} ${VALA_C})
# Vala uses deprecated glib async functions
target_compile_options(${PROJECT_NAME} PUBLIC -Wno-deprecated-declarations)
# Vala uses lots of "incompatible" pointers
target_compile_options(${PROJECT_NAME} PUBLIC -Wno-incompatible-pointer-types)
# Vala likes to ignore const qulifiers
target_compile_options(${PROJECT_NAME} PUBLIC -Wno-discarded-qualifiers)
target_include_directories(${PROJECT_NAME} PUBLIC ${DEPS_INCLUDE_DIRS})
target_link_libraries(${PROJECT_NAME} ${DEPS_LIBRARIES})
