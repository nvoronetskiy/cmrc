function(cmrc_add_test)
    set(options WILL_FAIL)
    set(args NAME PASS_REGEX WHENCE PREFIX)
    set(list_args RESOURCES TEST_ARGV)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${options}" "${args}" "${list_args}")

    if(DEFINED ARG_WHENCE)
        set(whence_arg WHENCE "${ARG_WHENCE}")
    endif()
    if(DEFINED ARG_PREFIX)
        set(prefix_arg PREFIX "${ARG_PREFIX}")
    endif()

    add_executable("${ARG_NAME}" "${ARG_NAME}.cpp")
    cmrc_add_resource_library(rc_${ARG_NAME} NAMESPACE "${ARG_NAME}" ${whence_arg} ${prefix_arg} ${ARG_RESOURCES})
    target_link_libraries("${ARG_NAME}" PRIVATE rc_${ARG_NAME})
    add_test("${ARG_NAME}" "${ARG_NAME}" ${ARG_TEST_ARGV})
    if(DEFINED ARG_PASS_REGEX)
        set_property(
            TEST "${ARG_NAME}"
            PROPERTY PASS_REGULAR_EXPRESSION "${ARG_PASS_REGEX}"
            )
    endif()
    if(ARG_UNPARSED_ARGUMENTS)
        message(WARNING "Invalid test arguments: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    set_property(TEST "${ARG_NAME}" PROPERTY WILL_FAIL "${ARG_WILL_FAIL}")
endfunction()

cmrc_add_test(
    NAME simple
    PASS_REGEX "^Hello, world!"
    RESOURCES
        hello.txt
        # Resources not used by the test, but just make sure we get no compilation
        # errors with the more complex paths:
        subdir_a/subdir_b/file_a.txt
        subdir_a/subdir_b/file_b.txt
    )

cmrc_add_test(
    NAME flower
    RESOURCES flower.jpg
    TEST_ARGV "${CMAKE_CURRENT_SOURCE_DIR}/flower.jpg"
    )

cmrc_add_test(
    NAME prefix
    PASS_REGEX "^Hello, world!"
    RESOURCES hello.txt
    PREFIX some-prefix
    )

cmrc_add_test(
    NAME whence
    PASS_REGEX "^I am a file!"
    RESOURCES subdir_a/subdir_b/file_a.txt
    WHENCE subdir_a
    )

cmrc_add_test(
    NAME whence_prefix
    PASS_REGEX "^I am a file!"
    RESOURCES subdir_a/subdir_b/file_b.txt
    WHENCE subdir_a
    PREFIX imaginary-prefix/
    )

cmrc_add_test(
    NAME iterate
    PASS_REGEX "^subdir_a\nfile_a.txt\nfile_b.txt\n$"
    RESOURCES
        subdir_a/subdir_b/file_a.txt
        subdir_a/subdir_b/file_b.txt
    )

cmrc_add_test(
    NAME enoent
    WILL_FAIL
    )

# PNG→webp conversion needs ImageMagick. Skip these tests if magick is absent so
# the rest of the suite still runs.
find_program(MAGICK magick)
if(NOT MAGICK)
    message(STATUS "Skipping webp tests: magick not found")
    return()
endif()

function(cmrc_add_webp_test)
    set(args NAME WHENCE PREFIX)
    set(list_args RESOURCES TEST_ARGV)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "${args}" "${list_args}")

    if(DEFINED ARG_WHENCE)
        set(whence_arg WHENCE "${ARG_WHENCE}")
    endif()
    if(DEFINED ARG_PREFIX)
        set(prefix_arg PREFIX "${ARG_PREFIX}")
    endif()

    add_executable("${ARG_NAME}" webp_embed.cpp)
    target_compile_definitions("${ARG_NAME}" PRIVATE "WEBP_TEST_NS=${ARG_NAME}")
    cmrc_add_resource_library(rc_${ARG_NAME} NAMESPACE "${ARG_NAME}" ${whence_arg} ${prefix_arg} ${ARG_RESOURCES})
    target_link_libraries("${ARG_NAME}" PRIVATE rc_${ARG_NAME})
    add_test("${ARG_NAME}" "${ARG_NAME}" ${ARG_TEST_ARGV})
endfunction()

cmrc_add_webp_test(
    NAME webp_smoke
    RESOURCES tiny.png
    TEST_ARGV tiny.png
    )

# Long OUTPUT path cannot go through MSVC: cl.exe also hits MAX_PATH on the
# generated .cpp. Exercise magick+copy via cmake -P instead.
set(webp_long_out_dir "${CMAKE_CURRENT_BINARY_DIR}/long_out")
set(webp_long_out_cpp "${webp_long_out_dir}/out.cpp")
string(LENGTH "${webp_long_out_cpp}.webp" _webp_out_len)
while(_webp_out_len LESS_EQUAL 270)
    set(webp_long_out_dir "${webp_long_out_dir}/xxxxxxxxxxxxxxxxxxxx")
    set(webp_long_out_cpp "${webp_long_out_dir}/out.cpp")
    string(LENGTH "${webp_long_out_cpp}.webp" _webp_out_len)
endwhile()
file(MAKE_DIRECTORY "${webp_long_out_dir}")

add_test(
    NAME webp_long_output
    COMMAND "${CMAKE_COMMAND}"
        -D_CMRC_GENERATE_MODE=TRUE
        -DNAMESPACE=webp_long_output
        -DSYMBOL=f_test
        "-DINPUT_FILE=${CMAKE_CURRENT_SOURCE_DIR}/tiny.png"
        "-DOUTPUT_FILE=${webp_long_out_cpp}"
        -P "${_CMRC_SCRIPT}"
    )

# Long INPUT path: copy the fixture into a deep tree under the build directory.
set(webp_long_input_dir "${CMAKE_CURRENT_BINARY_DIR}/long_in")
set(webp_long_input_file "${webp_long_input_dir}/tiny.png")
string(LENGTH "${webp_long_input_file}" _webp_in_len)
while(_webp_in_len LESS_EQUAL 270)
    set(webp_long_input_dir "${webp_long_input_dir}/d0123456789abcdef")
    set(webp_long_input_file "${webp_long_input_dir}/tiny.png")
    string(LENGTH "${webp_long_input_file}" _webp_in_len)
endwhile()
file(MAKE_DIRECTORY "${webp_long_input_dir}")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/tiny.png" "${webp_long_input_file}" COPYONLY)

cmrc_add_webp_test(
    NAME webp_long_input
    RESOURCES "${webp_long_input_file}"
    WHENCE "${webp_long_input_dir}"
    TEST_ARGV tiny.png
    )