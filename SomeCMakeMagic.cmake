
### THE MAGIC CMAKE MACROS - DO NOT CHANGE WITHOUT CONSULTING ORIGINAL AUTHOR ###

# Find all child directories in this folder -> result gets set to var "result"
macro(subdirlist result curdir)
    set(${result} "")
    file(GLOB children RELATIVE ${curdir} ${curdir}/*)
    set(dirlist "")
    foreach(child ${children})
        if(IS_DIRECTORY ${curdir}/${child})
            list(APPEND dirlist ${child})
        endif()
    endforeach()
    set(${result} ${dirlist})
endmacro()

# Determine the current directory's name -> result gets set to var "result"
macro(dirname result curdir)
    set(${result} "")
    get_filename_component(dirname ${curdir} NAME)
    string(REPLACE " " "_" dirname ${dirname})
    set(${result} ${dirname})
endmacro()

# Given a directory, list all of its source files (.h/.hpp/.c/.cc/.cpp/.cxx)
macro(list_source_files result curdir recursive exclude_dirs)
    if (${recursive})
        set(GLOB_COMMAND GLOB_RECURSE)
    else()
        set(GLOB_COMMAND GLOB)
    endif()
    file(${GLOB_COMMAND} files # RELATIVE ${curdir}
            "${curdir}/*.h"
            "${curdir}/*.hpp"
            "${curdir}/*.c"
            "${curdir}/*.cc"
            "${curdir}/*.cpp"
            "${curdir}/*.cxx"
            )

    # because of the heirarchical/recursive nature of variables in cmake,
    # it's necessary to reset the result var here to make sure that it
    # isn't accidentally used elsewhere
    set(${result} "")

    # file(GLOB...) gives a string instead of a list,
    # therefore the below foreach() sees the all files as one
    # as a result the string needs to be split into a list,
    # before it can be made into a string again, and finally
    # converted back into a list after the current directory is appended
    set(files_list ${files})
    separate_arguments(files_list)

    # process files, if any
    if (NOT "${files}" STREQUAL "")
        # append the given current directory to all found files to get their absolute path
        foreach(file ${files_list})
            set(${result} "${${result}}${file} ")
        endforeach()

        # remove extra spaces from the overall string
        string(STRIP ${${result}} ${result})

        # take the output of STRIP and convert it from a
        # space-separated string of files into a list
        # and assign it to the result variable
        separate_arguments(${result})
    endif()

    # get all files (absolute) from exclude_dirs
    foreach(excl_dir ${exclude_dirs})
        list_source_files(single_excl_dir_files ${curdir}/${excl_dir} true "")
        list(APPEND excl_files ${single_excl_dir_files})
    endforeach()

    # remove all excl files from results lists
    if (excl_files)
        separate_arguments(excl_files)
        list(REMOVE_ITEM ${result} ${excl_files})
    endif()
endmacro()

# recursively link all libraries in the given directory
macro(link_libraries _curr_dir _target _recursive _excl_dirs)
    # reset some temp vars to be safe
    set(_source_files "")
    set(_sub_dir "")
    set(_sub_dir "")
    set(_excl_dir "")

    # get all source files in the CURRENT DIRECTORY
    list_source_files(_source_files ${_curr_dir} false "")

    # using the target name, create the target/add it
    add_library(${_target} SHARED ${_source_files})

    # for some reason cmake needs to know we're using c++,
    # even though this is a c++ project...
    set_target_properties(${_target} PROPERTIES LINKER_LANGUAGE CXX)

    if (${_recursive})
        # get all child/sub directories in the current directory
        subdirlist(_sub_dirs ${_curr_dir})
        foreach(_sub_dir ${_sub_dirs})
            # exclude specified directories, if any
            if ("${_excl_dirs}" STREQUAL "" OR NOT ${_sub_dir} IN_LIST _excl_dirs)
                # link all targets from all child directories
                target_link_libraries(${_target} ${_target}_${_sub_dir})

                # recur on this method to do the same to all subdirs
                link_libraries("${_curr_dir}/${_sub_dir}" "${_target}_${_sub_dir}" ${_recursive} "")
            endif()
        endforeach()
    endif()
endmacro()

# recursively build all targets/executables in the given directory
# and add them to the project
macro(build_execs _curr_dir _target _recursive _excl_dirs)
    # reset some temp vars to be safe
    set(_source_files "")
    set(_sub_dir "")
    set(CLIENT_LIBS "")

    # get all source files in the CURRENT DIRECTORY
    list_source_files(_source_files ${_curr_dir} false lib)

    if (_source_files)
        add_executable(${_target} ${_source_files})

        set(CLIENT_LIBS src tests_lib)

        target_link_libraries(${_target} ${CLIENT_LIBS})

        linksfml(${_target} ${_curr_dir})
        linktinyxml(${_target} ${_curr_dir})
    endif()

    if (${_recursive})
        # get all child/sub directories in the current directory
        subdirlist(_sub_dirs ${_curr_dir})
        foreach(_sub_dir ${_sub_dirs})
            # exclude specified directories, if any
            if ("${_excl_dirs}" STREQUAL "" OR NOT ${_sub_dir} IN_LIST _excl_dirs)
                # build executables in all child directories
                if ("${_source_files}")
                    target_link_libraries(${_target} ${_target}_${_sub_dir})
                endif()

                # recur on this method to do the same to all subdirs
                build_execs("${_curr_dir}/${_sub_dir}"
                        "${_target}_${_sub_dir}"
                        ${_recursive} ${_excl_dirs})
            endif()
        endforeach()
    endif()
endmacro()

# get all resource files and link them locally so fs absolute paths aren't necessary
macro(get_resources res_dir)
    file(GLOB_RECURSE res_files RELATIVE ${res_dir} "*")
    foreach(f ${res_files})
        configure_file(${res_dir}/${f} ${f} COPYONLY)
    endforeach()
endmacro()
