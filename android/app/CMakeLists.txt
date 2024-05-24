cmake_minimum_required(VERSION 3.29.3)
project(split_pdf)

set(MUPDF_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/../../clib/mupdf/include)
set(MUPDF_LIB_DIR ${CMAKE_SOURCE_DIR}/../../clib/mupdf/build/android/libs/${ANDROID_ABI})
#set(MUPDF_LIB_DIR ${CMAKE_SOURCE_DIR}/../../clib/mupdf/build/release)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

find_library(MUPDF_LIB mupdf HINTS ${MUPDF_LIB_DIR})
find_library(MUPDF_THIRD_LIB mupdf-third HINTS ${MUPDF_LIB_DIR})

include_directories(${MUPDF_INCLUDE_DIR})
link_directories(${MUPDF_LIB_DIR})

# MuPDF wrapper 소스 파일
set(SRC_FILES ${CMAKE_SOURCE_DIR}/../../clib/split_pdf.cpp)

# split_pdf 라이브러리 추가
add_library(split_pdf SHARED ${SRC_FILES})

# AddressSanitizer 및 디버그 정보 추가
#target_compile_options(split_pdf PRIVATE -g -fsanitize=address)
#target_link_options(split_pdf PRIVATE -fsanitize=address)

#target_link_libraries(split_pdf ${MUPDF_LIB} ${MUPDF_THIRD_LIB})
target_link_libraries(split_pdf mupdf_java)