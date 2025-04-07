cmake_minimum_required(VERSION 3.28)

project(fish-blast)

include(cmake/deps.cmake)


add_library(fish-blast SHARED)
target_sources(fish-blast 
    PRIVATE FILE_SET CXX_MODULES FILES
        "src/entry_main.ixx"
        "src/menus.ixx"
   "src/player.ixx")

target_link_libraries(fish-blast PRIVATE godot::cpp reflect)
set_target_properties(fish-blast PROPERTIES 
    CXX_STANDARD 23
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
    CXX_SCAN_FOR_MODULES ON
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin"
)

set(DLLPATH "fish-blast.dll")
configure_file("cmake/gdext.in"
               "${CMAKE_CURRENT_SOURCE_DIR}/bin/fish-blast.gdextension" @ONLY)