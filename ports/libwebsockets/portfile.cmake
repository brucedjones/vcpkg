include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO warmcat/libwebsockets
    REF v2.4.1
    SHA512 a5f6a3388517d6f46183dfd1e625475ac1d4d509690e431a581d6ca927078fa50ac9a0787b4305fe088c694af1809335020bfc083a4d4d98585143f13ff61c75
    HEAD_REF master
)

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/0001-Fix-UWP.patch
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" LWS_WITH_STATIC)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" LWS_WITH_SHARED)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        -DLWS_WITH_STATIC=${LWS_WITH_STATIC}
        -DLWS_WITH_SHARED=${LWS_WITH_SHARED}
        -DLWS_USE_BUNDLED_ZLIB=OFF
        -DLWS_WITHOUT_TESTAPPS=ON
        -DLWS_IPV6=ON
        -DLWS_HTTP2=ON
    # OPTIONS_RELEASE -DOPTIMIZE=1
    # OPTIONS_DEBUG -DDEBUGGABLE=1
)

vcpkg_install_cmake()

vcpkg_fixup_cmake_targets(CONFIG_PATH "cmake")

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/share/libwebsockets-test-server)
file(READ ${CURRENT_PACKAGES_DIR}/share/libwebsockets/LibwebsocketsConfig.cmake LIBWEBSOCKETSCONFIG_CMAKE)
string(REPLACE "/../include" "/../../include" LIBWEBSOCKETSCONFIG_CMAKE "${LIBWEBSOCKETSCONFIG_CMAKE}")
file(WRITE ${CURRENT_PACKAGES_DIR}/share/libwebsockets/LibwebsocketsConfig.cmake "${LIBWEBSOCKETSCONFIG_CMAKE}")
file(READ ${CURRENT_PACKAGES_DIR}/share/libwebsockets/LibwebsocketsTargets-debug.cmake LIBWEBSOCKETSTARGETSDEBUG_CMAKE)
string(REPLACE "websockets_static.lib" "websockets.lib" LIBWEBSOCKETSTARGETSDEBUG_CMAKE "${LIBWEBSOCKETSTARGETSDEBUG_CMAKE}")
file(WRITE ${CURRENT_PACKAGES_DIR}/share/libwebsockets/LibwebsocketsTargets-debug.cmake "${LIBWEBSOCKETSTARGETSDEBUG_CMAKE}")
file(READ ${CURRENT_PACKAGES_DIR}/share/libwebsockets/LibwebsocketsTargets-release.cmake LIBWEBSOCKETSTARGETSRELEASE_CMAKE)
string(REPLACE "websockets_static.lib" "websockets.lib" LIBWEBSOCKETSTARGETSRELEASE_CMAKE "${LIBWEBSOCKETSTARGETSRELEASE_CMAKE}")
file(WRITE ${CURRENT_PACKAGES_DIR}/share/libwebsockets/LibwebsocketsTargets-release.cmake "${LIBWEBSOCKETSTARGETSRELEASE_CMAKE}")
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/libwebsockets)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/libwebsockets/LICENSE ${CURRENT_PACKAGES_DIR}/share/libwebsockets/copyright)
if (VCPKG_LIBRARY_LINKAGE STREQUAL static)
    file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/websockets_static.lib ${CURRENT_PACKAGES_DIR}/debug/lib/websockets.lib)
    file(RENAME ${CURRENT_PACKAGES_DIR}/lib/websockets_static.lib ${CURRENT_PACKAGES_DIR}/lib/websockets.lib)
endif ()
vcpkg_copy_pdbs()
