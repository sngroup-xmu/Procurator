# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/translate/cmake/version.h.cmake"
  "${CMAKE_CURRENT_BINARY_DIR}/translate/version.h" @ONLY)

option(ENABLE_P4VERIFY_P4LTL
  "Build legacy P4LTL support for the verify backend" OFF)

set (P4VERIFY_BACKEND_VERIFY_SRCS
  bpl_verify/main.cpp
  bpl_verify/frontend.h
  bpl_verify/frontend.cpp
  bpl_verify/pipeline.h
  bpl_verify/pipeline.cpp
  analysis/index_defs.h
  analysis/index_defs.cpp
  analysis/monotonic.h
  analysis/monotonic.cpp
  slicing/collectors/register_decl.h
  slicing/collectors/register_decl.cpp
  slicing/slicer.cpp
  slicing/slicer_apply.cpp
  slicing/slicer_dot.cpp
  slicing/slicer.h
  slicing/slicer_selftest.cpp
  slicing/slicer_selftest.h
)
add_cpplint_files (${CMAKE_CURRENT_SOURCE_DIR} "${P4VERIFY_BACKEND_VERIFY_SRCS}")

set (P4VERIFY_BACKEND_TRANSLATE_SRCS
  translate/options.h
  translate/translate.h
  translate/impl/core/translate.cpp
  translate/impl/lowering/translate_program.cpp
  translate/impl/lowering/translate_statement.cpp
  translate/impl/lowering/translate_expression.cpp
  translate/impl/lowering/translate_method.cpp
  translate/impl/lowering/translate_type.cpp
  translate/impl/lowering/translate_operator.cpp
  translate/impl/lowering/translate_bitblast.cpp
  translate/impl/lowering/translate_table.cpp
  translate/impl/meta/meta_emit.cpp
  translate/analyzer.h
  translate/impl/support/analyzer.cpp
  translate/boogie_procedure.h
  translate/impl/support/boogie_procedure.cpp
  translate/boogie_statement.h
  translate/impl/support/boogie_statement.cpp
  translate/bmv2.h
  translate/impl/support/bmv2.cpp
  translate/p4ltl_utils.h
  translate/utils.h
  translate/impl/support/utils.cpp
)
if (ENABLE_P4VERIFY_P4LTL)
  list(APPEND P4VERIFY_BACKEND_TRANSLATE_SRCS
    translate/impl/support/p4ltl_utils.cpp
  )
  add_compile_definitions(P4VERIFY_ENABLE_P4LTL=1)
endif ()
add_cpplint_files (${CMAKE_CURRENT_SOURCE_DIR} "${P4VERIFY_BACKEND_TRANSLATE_SRCS}")


build_unified(P4VERIFY_BACKEND_TRANSLATE_SRCS)
add_library(verifybackend ${P4VERIFY_BACKEND_TRANSLATE_SRCS})
target_include_directories(verifybackend PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/translate)
target_link_libraries(verifybackend PUBLIC ir-generated frontend p4ctoolkit)
target_compile_definitions(verifybackend PUBLIC P4VERIFY_LEGACY_CSTRING_IMPLICIT=1)
add_dependencies(verifybackend genIR frontend)

build_unified(P4VERIFY_BACKEND_VERIFY_SRCS)
add_executable(p4c-translator ${P4VERIFY_BACKEND_VERIFY_SRCS})
# NOTE: Our vendored snapshot does not include the `control-plane/p4runtime` proto
# submodule, which makes the `controlplane` library (and any executable that links
# it) fail to build. The `p4c-translator` backend does not depend on control-plane,
# so we link only the core component libraries here.
target_link_libraries (p4c-translator verifybackend midend frontend ir p4ctoolkit ${P4C_LIB_DEPS})


install(TARGETS p4c-translator RUNTIME DESTINATION ${P4C_RUNTIME_OUTPUT_DIRECTORY})

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

add_dependencies(linkp4verify update_includes)
add_dependencies(p4c-translator linkp4verify)
add_dependencies(p4c_driver linkp4verify)
