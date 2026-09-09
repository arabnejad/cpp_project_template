cmake_minimum_required(VERSION 3.21)

project(app_package_consumer LANGUAGES CXX)

find_package(app CONFIG REQUIRED)

add_executable(package_consumer main.cpp)
target_link_libraries(package_consumer PRIVATE app::app_lib)

enable_testing()
add_test(NAME package_consumer_runs COMMAND package_consumer)
