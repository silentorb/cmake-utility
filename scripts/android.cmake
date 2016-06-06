unset(MSVC)
unset(MINGW)
message("Generating for Android")
cmake_policy(SET CMP0011 NEW)
cmake_policy(SET CMP0057 NEW)

macro(append_target_property property_name value)
  set(${CURRENT_TARGET}_${property_name} ${${CURRENT_TARGET}_${property_name}} ${value})
  set(${CURRENT_TARGET}_${property_name} ${${CURRENT_TARGET}_${property_name}} PARENT_SCOPE)
endmacro()

macro(set_target_property property_name value)
  set(${CURRENT_TARGET}_${property_name} ${value})
  set(${CURRENT_TARGET}_${property_name} ${${CURRENT_TARGET}_${property_name}} PARENT_SCOPE)
endmacro()

macro(add_library target)
  #  set(${target}_sources ${ARGN})
  #  set(${target}_sources ${ARGN} PARENT_SCOPE)
  create_library(${target} ${ARGN})
  message("target ${target}")
endmacro()

macro(project target)
  message("project ${target}")
  set(PROJECT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
  set(${target}_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

  file(RELATIVE_PATH relative_path ${CMAKE_ROOT} ${CMAKE_CURRENT_SOURCE_DIR})

  #  message("**** ${CMAKE_SOURCE_DIR}    ${CMAKE_CURRENT_SOURCE_DIR}")
  if (${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
    set(PROJECT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    set(${target}_BINARY_DIR ${PROJECT_BINARY_DIR})
  else ()
    string(LENGTH "${CMAKE_SOURCE_DIR}" root_length)
    math(EXPR root_length "${root_length} + 1")
    string(SUBSTRING ${CMAKE_CURRENT_SOURCE_DIR} ${root_length} -1 relative_path)
    #  message("Relative ${relative_path}")
    set(PROJECT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${relative_path}")
    set(${target}_BINARY_DIR ${PROJECT_BINARY_DIR})
  endif ()
  get_directory_property(has_parent PARENT_DIRECTORY)
  if (has_parent)
    set(PROJECT_NAME ${target} PARENT_SCOPE)
    set(PROJECT_NAME ${target})
  else ()
    set(PROJECT_NAME ${target})
  endif ()

endmacro()

macro(android_create_entrypoint target)
  #  add_custom_target(${target})
  #  set(${target}_sources ${ARGN} PARENT_SCOPE)
  create_library(${target} ${ARGN})
  set(${target}_is_executable 1 PARENT_SCOPE)
  set(application_name ${target} PARENT_SCOPE)

endmacro()

macro(add_sources)
  foreach (source ${ARGN})
    get_filename_component(absolute_path ${source} ABSOLUTE)
    set(${CURRENT_TARGET}_sources ${${CURRENT_TARGET}_sources} ${absolute_path})
  endforeach ()
  set(${CURRENT_TARGET}_sources ${${CURRENT_TARGET}_sources} PARENT_SCOPE)
endmacro()

macro(add_system_libraries)
  if (NOT "${ARGN}" STREQUAL "")
    set(${CURRENT_TARGET}_system_libraries ${${CURRENT_TARGET}_system_libraries} ${ARGN})
    list(REMOVE_DUPLICATES ${CURRENT_TARGET}_system_libraries)
    set(${CURRENT_TARGET}_system_libraries ${${CURRENT_TARGET}_system_libraries} PARENT_SCOPE)
  endif ()
endmacro()

macro(include_directories)
  set(${CURRENT_TARGET}_includes ${${CURRENT_TARGET}_includes} ${ARGN})
  set(${CURRENT_TARGET}_includes ${${CURRENT_TARGET}_includes} ${ARGN} PARENT_SCOPE)
  #      message("  ${CURRENT_TARGET}")
  #  message(${${CURRENT_TARGET}_includes})
endmacro()

macro(android_add_project project_name)
  if (${MINGW})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  endif ()

  project(${project_name})
  set(${project_name}_DIR ${CMAKE_CURRENT_LIST_DIR} PARENT_SCOPE)
  include(${project_name}-config.cmake OPTIONAL)

endmacro()

macro(create_library target)
  set(all_libraries ${all_libraries} ${target} PARENT_SCOPE)
  set(CURRENT_TARGET ${target})
  if (NOT "${PROJECT_NAME}" STREQUAL ${target})
    android_add_project(${target})
  endif ()

  if (NOT "${ARGN}" STREQUAL "")
    set_target_property(sources "${ARGN}")
  else ()
    file(GLOB_RECURSE SOURCES source/*.cpp source/*.c)
    if (SOURCES)
      append_target_property(sources ${SOURCES})
    endif ()
  endif ()

  string(LENGTH "${CMAKE_SOURCE_DIR}" string_length)
  math(EXPR string_length "${string_length} + 1")
  string(SUBSTRING ${CMAKE_CURRENT_SOURCE_DIR} ${string_length} -1 current_path)
  set(${target}_relative_path ${current_path} PARENT_SCOPE)
  get_filename_component(current_path ${current_path} DIRECTORY)
  set(${target}_containing_path ${current_path} PARENT_SCOPE)

  include_directories(${CMAKE_TOOLS}/include) # for dllexport

endmacro(create_library)

macro(get_relative_path result root_path path)
  string(LENGTH "${root_path}" string_length)
  math(EXPR string_length "${string_length} + 1")
  string(SUBSTRING ${path} ${string_length} -1 ${result})
endmacro(get_relative_path)

macro(create_test target)

endmacro(create_test)

macro(android_add_library library_name)
  set(${CURRENT_TARGET}_libraries ${${CURRENT_TARGET}_libraries} ${library_name})
  set(${CURRENT_TARGET}_libraries ${${CURRENT_TARGET}_libraries} PARENT_SCOPE)
endmacro()

macro(require)
  foreach (library_name ${ARGN})
    find_package(${library_name} REQUIRED)

    if (${library_name} IN_LIST all_libraries)
      android_add_library(${library_name})
      #    set(${CURRENT_TARGET}_libraries ${${CURRENT_TARGET}_libraries} ${library_name})
      #    set(${CURRENT_TARGET}_libraries ${${CURRENT_TARGET}_libraries} PARENT_SCOPE)
      add_system_libraries(${${library_name}_system_libraries})
    endif ()

  endforeach ()
endmacro()

macro(add name)
  add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/${name})
endmacro(add)

macro(add_resources resources_dir)
  set(${CURRENT_TARGET}_resources_dir ${CMAKE_CURRENT_LIST_DIR}/${resources_dir} PARENT_SCOPE)
endmacro(add_resources)

macro(finish_mythic)
  include(${CMAKE_TOOLS}/generators/android/android-generator.cmake)
  message(FATAL_ERROR "This is not a real error, but the only way to prevent CMake from generating unneeded files.")
endmacro(finish_mythic)


macro(doctor varname path name extension)
  if (path AND EXISTS ${path}/${name}.${extension})
  else ()
    string(SUBSTRING "${name}" 0 3 libprefix)
    if (NOT libprefix STREQUAL "lib")
      set(name "lib${name}")
    endif ()
  endif ()

  set(name2 name)
  set(extension2 extension)
  set(${varname} "${${name2}}.${${extension2}}" PARENT_SCOPE)
endmacro()

function(doctor_dynamic varname path)
  set(name ${${varname}})
  set(extension "a")

  doctor(${varname} ${path} ${name} ${extension})

endfunction()

function(doctor_static varname path is_dynamic)
  set(name ${${varname}})
  set(extension "a")
  doctor(${varname} ${path} ${name} ${extension})

endfunction()

macro(include_external_directory path)
  set(include_suffix "${ARGV1}")
  if (NOT include_suffix)
    set(include_suffix "")
  else ()
    set(include_suffix "/${include_suffix}")
  endif ()

  include_directories(${MYTHIC_DEPENDENCIES}/${path}/include${include_suffix})

endmacro()

macro(link_external_static path)
  android_add_library(${path})
#  set(libname "${ARGV1}")
#  set(is_dynamic "${ARGV2}")
#  if (NOT is_dynamic)
#    set(is_dynamic FALSE)
#  endif ()
#
#  if (NOT libname)
#    set(libname ${path})
#  endif ()
#
#  set(include_suffix "${ARGV3}")
#  if (NOT include_suffix)
#    set(include_suffix "")
#  else ()
#    set(include_suffix "/${include_suffix}")
#  endif ()
#
#  set(fullpath ${MYTHIC_DEPENDENCIES}/${path}/lib)
#  doctor_static(libname ${fullpath} ${is_dynamic})
#
#  #  target_link_libraries(${CURRENT_TARGET} "${fullpath}/${libname}")
#  android_add_library("${fullpath}/${libname}")
#
#  include_directories(${MYTHIC_DEPENDENCIES}/${path}/include${include_suffix})

endmacro()

macro(link_external path)
  set(libname "${ARGV1}")
  if (NOT libname)
    set(libname ${path})
  endif ()

  set(dllname "${ARGV2}")
  if (NOT dllname)
    set(dllname ${libname})
  endif ()

  link_external_static(${path} ${libname})
endmacro()

macro(set_target_properties target PROPERTIES)
  if (${ARGV2} STREQUAL DEFINE_SYMBOL)
    append_target_property(defines ${ARGV3})
  endif ()
endmacro()

macro(install)
endmacro()

macro(find_package)
endmacro()

macro(target_include_directories)
  #  set(args "${ARGN}")
  #  foreach (arg IN LISTS args)
  #    if (NOT arg STREQUAL "INTERFACE")
  #
  #    endif ()
  #  endforeach ()
endmacro()

macro(export)
endmacro()

macro(target_link_libraries target)
  #  require(${ARGN})
  set(args "${ARGN}")
  foreach (arg IN LISTS args)
    require(${arg})
  endforeach ()
endmacro()