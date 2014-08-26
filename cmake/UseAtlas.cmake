if (WIN32)
#        option(USE_ATLAS "Build the project using ATLAS" OFF)
#        mark_as_advanced(USE_ATLAS)
        option(USE_MKL "Build the project with MKL" ON)
        mark_as_advanced(USE_MKL)
        if (NOT BUILD_SHARED_LIBS)
            set(CMAKE_FIND_LIBRARY_SUFFIXES ".lib;.dll")
        endif()
else()
    option(USE_ATLAS "Build the project using ATLAS" ON)
    option(USE_MKL "Build the project with MKL" OFF)
    if (NOT BUILD_SHARED_LIBS)
        if (APPLE)   # MACOSX
            set(CMAKE_FIND_LIBRARY_SUFFIXES ".a;.so;.dylib")
        else() # LINUX
            set(CMAKE_FIND_LIBRARY_SUFFIXES ".a;.so")
        endif()
    endif()
endif()

if (USE_MKL AND USE_ATLAS)
    message(ERROR "USE_ATLAS and USE_MKL are mutually incompatible, if both are false then standard lapcal is used.")
endif()

if (USE_MKL)
	find_package(MKL)
	if (MKL_FOUND)
		include_directories(${MKL_INCLUDE_DIR})
        set(lapack_DIR ${MKL_ROOT_DIR})
		set(LAPACK_LIBRARIES ${MKL_LIBRARIES})
        #message(${LAPACK_LIBRARIES}) # for debug
		if(UNIX AND NOT APPLE) # MKL on linux requires to link with the pthread library
			set(LAPACK_LIBRARIES ${LAPACK_LIBRARIES} pthread)
		endif()
	else()
		message(FATAL_ERROR "MKL not found. Please set environment variable MKLDIR")
	endif()
endif()

if (USE_ATLAS)
    if (APPLE)
        set(LAPACK_LIBRARIES "-framework vecLib")
        include_directories(/System/Library/Frameworks/vecLib.framework/Headers)
    else()
        set(ATLAS_LIB_SEARCHPATH
            /usr/lib64/
            /usr/lib64/atlas
            /usr/lib64/atlas/sse2
            /usr/lib/atlas/sse2
            /usr/lib/sse2
            /usr/lib64/atlas/sse3
            /usr/lib/atlas/sse3
            /usr/lib/sse3
            /usr/lib/
            /usr/lib/atlas
            /usr/lib/atlas-base
            /usr/lib64/atlas-base
            )
        set(ATLAS_LIBS atlas cblas f77blas clapack lapack blas)

        find_path(ATLAS_INCLUDE_PATH clapack.h /usr/include/atlas /usr/include/ NO_DEFAULT_PATH)
        find_path(ATLAS_INCLUDE_PATH clapack.h)
        mark_as_advanced(ATLAS_INCLUDE_PATH)
        include_directories(${ATLAS_INCLUDE_PATH})
        foreach (LIB ${ATLAS_LIBS})
            set(LIBNAMES ${LIB})
            if (${LIB} STREQUAL "clapack")
                set(LIBNAMES ${LIB} lapack_atlas)
            endif()
            find_library(${LIB}_PATH
                NAMES ${LIBNAMES}
                PATHS ${ATLAS_LIB_SEARCHPATH}
                NO_DEFAULT_PATH
                NO_CMAKE_ENVIRONMENT_PATH
                NO_CMAKE_PATH
                NO_SYSTEM_ENVIRONMENT_PATH
                NO_CMAKE_SYSTEM_PATH)
            if(${LIB}_PATH)
                set(lapack_DIR ${${LIB}_PATH})
                set(LAPACK_LIBRARIES ${LAPACK_LIBRARIES} ${${LIB}_PATH})
                mark_as_advanced(${LIB}_PATH)
            else()
                message(WARNING "Could not find ${LIB}")
            endif()
        endforeach()
    endif()
endif()

if (NOT USE_ATLAS AND NOT USE_MKL)
    set(lapack_libs_dir ${lapack_DIR}/lib)
    find_package(lapack QUIET PATHS /usr/lib64/ /usr/lib/ ${lapack_libs_dir}
                 NO_DEFAULT_PATH
                 NO_CMAKE_ENVIRONMENT_PATH
                 NO_CMAKE_PATH
                 NO_SYSTEM_ENVIRONMENT_PATH
                 NO_CMAKE_SYSTEM_PATH)
    message("Lapack package: ${lapack}: ${LAPACK_LIBRARIES}")
endif()

#set(CMAKE_FIND_DEBUG_MODE 1)
if (NOT LAPACK_LIBRARIES)
    message("Searching lapack in ${lapack_libs_dir}")
    find_library(lapack lapack  PATHS ${lapack_libs_dir})
    find_library(blas blas  PATHS ${lapack_libs_dir})
    find_library(f2c NAMES f2c libf2c  PATHS ${lapack_libs_dir})
    if (NOT (lapack AND blas AND f2c))
        message(SEND_ERROR "clapack is needed")
    endif()
    set(LAPACK_LIBRARIES ${lapack} ${blas} ${f2c})
    if (NOT BUILD_SHARED_LIBS)
        file(GLOB GCC_fileS "/usr/lib/gcc/*/*")
        find_file(GFORTRAN_LIB libgfortran.a ${GCC_fileS})
        set(LAPACK_LIBRARIES ${LAPACK_LIBRARIES} ${GFORTRAN_LIB})
    endif()
endif()

set(HAVE_LAPACK TRUE)
set(HAVE_BLAS TRUE)
