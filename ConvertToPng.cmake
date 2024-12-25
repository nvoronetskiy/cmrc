cmake_minimum_required(VERSION 3.25)

find_program(MAGICK "magick")
if(NOT MAGICK)
   if(APPLE)
        message(FATAL_ERROR "Please install imagemagick. See https://imagemagick.org/script/download.php")
   endif()
   message(WARNING "System ImageMagick not found. Will try to use bundled version")
   #FIXME: Correct relative path
   list(APPEND CMAKE_PROGRAM_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../../toolchain/tools/magick") 
endif()

# TODO: любые типы изображений, а не только png

# Конвертация одного файла
function(convert_png_to_webp in_file image_out)
    string(REGEX REPLACE "\.png$" "\.webp" out_file ${in_file})
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${out_file}
        COMMAND magick ARGS mogrify -format webp -quality 80 -define webp:lossless=false -define webp:method=6 -define webp:auto-filter=true ${in_file}
        COMMAND ${CMAKE_COMMAND} ARGS -E remove ${in_file}
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${in_file}
    )
    set(${image_out} ${out_file} PARENT_SCOPE)
endfunction()


# Конвертация одного файла
function(convert_to_webp in_file out_file)
    execute_process(COMMAND magick mogrify -format webp -quality 80 -define webp:lossless=false -define webp:method=6 -define webp:auto-filter=true -write ${out_file} ${in_file} )
endfunction()


# Конвертация списка файлов
function(convert_pngs_to_webp images_list_in images_list_out)
    foreach(in_file ${${images_list_in}})
        convert_png_to_webp(${in_file} out_file)
        list(APPEND processed_images_list "${CMAKE_CURRENT_BINARY_DIR}/${out_file}")
    endforeach()
    set(${images_list_out} ${processed_images_list} PARENT_SCOPE)
endfunction()
