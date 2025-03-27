include(FetchContent)
set(FETCHCONTENT_UPDATES_DISCONNECTED ON)
set(CPM_DONT_UPDATE_MODULE_PATH ON)
set(GET_CPM_FILE "${CMAKE_CURRENT_LIST_DIR}/get_cpm.cmake")

if (NOT EXISTS ${GET_CPM_FILE})
  file(DOWNLOAD
      https://github.com/cpm-cmake/CPM.cmake/releases/latest/download/get_cpm.cmake
      "${GET_CPM_FILE}"
  )
endif()
include(${GET_CPM_FILE})

# Add CPM dependencies here
# godot-cpp
CPMAddPackage(
  NAME godot-cpp
  GITHUB_REPOSITORY godotengine/godot-cpp
  GIT_TAG 4.3
)

# Reflect
CPMAddPackage(
  NAME Reflect
  GITHUB_REPOSITORY qlibs/reflect
  GIT_TAG v1.2.4
)
add_library(reflect INTERFACE)
target_include_directories(reflect INTERFACE ${Reflect_SOURCE_DIR})