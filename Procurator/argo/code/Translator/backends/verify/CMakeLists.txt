# 配置版本文件
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/translate/version.h.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/translate/version.h" @ONLY)

# 定义源文件列表
set(P4VERIFY_BACKEND_TRANSLATE_SRCS
        translate/options.h
        translate/translate.h
        translate/translate.cpp
        translate/analyzer.h
        translate/analyzer.cpp
        translate/boogie_procedure.h
        translate/boogie_procedure.cpp
        translate/boogie_statement.h
        translate/boogie_statement.cpp
        translate/bmv2.h
        translate/bmv2.cpp
        translate/utils.h
        translate/utils.cpp
        translate/bf4_assertion.h
        translate/bf4_assertion.cpp
        to_dsl/variable_collector.h
        to_dsl/variable_collector.cpp
        to_dsl/field_mapping.h
        to_dsl/field_mapping.cpp
        control_flow_analysis/control_flow_extractor.h
        control_flow_analysis/control_flow_extractor.cpp
        channel_extract/chan_extractor.cpp
        channel_extract/chan_extractor.h
        control_flow_analysis/sclicing_engine.cpp
        control_flow_analysis/sclicing_engine.h
        control_flow_analysis/structures.h
        control_flow_analysis/test/test_slicing.cpp
        control_flow_analysis/test/test_slicing.h
        control_flow_analysis/ir_id_collector.h
        control_flow_analysis/ir_id_collector.cpp
        control_flow_analysis/pdg_compute.h
        control_flow_analysis/pdg_compute.cpp
)

set(P4VERIFY_BACKEND_VERIFY_SRCS
        bpl_verify/main.cpp
)

# 添加库目标（注意，这里使用库名称 verifybackend）
add_library(verifybackend STATIC ${P4VERIFY_BACKEND_TRANSLATE_SRCS})

# 使用本地最小化 nlohmann/json 头文件以避免 FetchContent 拉取
add_library(nlohmann_json INTERFACE)
add_library(nlohmann_json::nlohmann_json ALIAS nlohmann_json)
target_include_directories(
        nlohmann_json
        INTERFACE
        "${CMAKE_CURRENT_SOURCE_DIR}/../../third_party"
)

# 添加可执行文件目标
add_executable(p4c-translator ${P4VERIFY_BACKEND_VERIFY_SRCS})

# 链接库到可执行文件
target_link_libraries(p4c-translator verifybackend ${P4C_LIBRARIES} ${P4C_LIB_DEPS} nlohmann_json::nlohmann_json)
target_link_libraries(verifybackend nlohmann_json::nlohmann_json)

# 设置依赖关系
add_dependencies(verifybackend genIR frontend)
add_dependencies(p4c-translator verifybackend)

# 安装可执行文件
install(TARGETS p4c-translator RUNTIME DESTINATION ${P4C_RUNTIME_OUTPUT_DIRECTORY})

# 创建符号链接（根据需要调整）
file(RELATIVE_PATH
        CURRENT_BINARY_DIR_PATH_REL
        ${P4C_BINARY_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}
)

file(RELATIVE_PATH
        P4C_BINARY_DIR_PATH_REL
        ${CMAKE_CURRENT_BINARY_DIR}
        ${P4C_BINARY_DIR}
)

add_custom_target(linkp4verify
        COMMAND ${CMAKE_COMMAND} -E create_symlink ${CURRENT_BINARY_DIR_PATH_REL}/p4c-translator ${P4C_BINARY_DIR}/p4c-translator
        COMMAND ${CMAKE_COMMAND} -E create_symlink ${P4C_BINARY_DIR_PATH_REL}/p4include ${CMAKE_CURRENT_BINARY_DIR}/p4include
        COMMAND ${CMAKE_COMMAND} -E create_symlink ${P4C_BINARY_DIR_PATH_REL}/p4_14include ${CMAKE_CURRENT_BINARY_DIR}/p4_14include
)

add_dependencies(p4c_driver linkp4verify)
