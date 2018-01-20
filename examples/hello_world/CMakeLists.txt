CMAKE_MINIMUM_REQUIRED(VERSION 3.8)

# create project name var and set the project name
set(PROJECT_NAME hello_world)
project(${PROJECT_NAME})

# explicitly state the C++ version - sometime CMake will get mad if you don't
set(CMAKE_CXX_STANDARD 11)
add_definitions(-std=c++11)

# get my magic macros
include(../../SomeCMakeMagic.cmake)

# make executable for running the example
list_source_files(src_files ${CMAKE_CURRENT_LIST_DIR} false "")
add_executable(${PROJECT_NAME} ${src_files})

