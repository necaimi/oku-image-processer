cmake_minimum_required(VERSION 3.10)
project(image_processor)

set(CMAKE_CXX_STANDARD 11)

# 强制优先寻找静态库，避免 DLL 依赖缺失问题
set(WebP_USE_STATIC_LIBS ON)

# 寻找 libwebp
find_package(WebP CONFIG REQUIRED)

add_library(image_processor SHARED 
    image_processor.cpp 
    image_processor.h
)

# 包含头文件路径
target_include_directories(image_processor PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# 链接 WebP 库
# 在 Windows 下，我们希望将其静态链接进 image_processor.dll
if(TARGET WebP::webp)
    target_link_libraries(image_processor PRIVATE WebP::webp)
else()
    target_include_directories(image_processor PRIVATE ${WebP_INCLUDE_DIRS})
    target_link_libraries(image_processor PRIVATE ${WebP_LIBRARIES})
endif()

# 如果是 Windows 且找到了 WebP，尝试链接其他可能的静态依赖（如 sharpyuv）
if(WIN32 AND TARGET WebP::sharpyuv)
    target_link_libraries(image_processor PRIVATE WebP::sharpyuv)
endif()

# 设置 Windows 下的 dll 输出目录
if(WIN32)
    set_target_properties(image_processor PROPERTIES 
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    )
endif()
