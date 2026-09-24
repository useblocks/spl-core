# boilerplate to get CMake running
cmake_minimum_required(VERSION 3.22.0)
project(test-common-cmake C ASM CXX)
set(VARIANT mytestvariant)
set(BUILD_KIT prod)

# ## IUT ####################################
include(${CMAKE_CURRENT_LIST_DIR}/../../../src/spl_core/common.cmake)

# ## test: _spl_slash_to_underscore #########
# given
set(string_with_slashes "abc/def/ghi")

# when
_spl_slash_to_underscore(string_with_underscore ${string_with_slashes})

# then
if(NOT string_with_underscore STREQUAL "abc_def_ghi")
    message(FATAL_ERROR "Failing Test case: string_with_slashes = ${string_with_slashes}.")
endif()

# ## test: _spl_source_doc_name (source doc name collision avoidance) #########
# given two sources sharing a basename in different sub-directories of a component

# when
_spl_source_doc_name(doc_name_a "${CMAKE_CURRENT_LIST_DIR}/component/src/foo.c" "${CMAKE_CURRENT_LIST_DIR}/component")
_spl_source_doc_name(doc_name_b "${CMAKE_CURRENT_LIST_DIR}/component/test/foo.c" "${CMAKE_CURRENT_LIST_DIR}/component")

# then: doc names keep the relative path, so they stay distinct instead of both becoming "foo.c"
if(NOT doc_name_a STREQUAL "src/foo.c")
    message(FATAL_ERROR "Failing Test case: expected 'src/foo.c' but got '${doc_name_a}'.")
endif()

if(NOT doc_name_b STREQUAL "test/foo.c")
    message(FATAL_ERROR "Failing Test case: expected 'test/foo.c' but got '${doc_name_b}'.")
endif()

if(doc_name_a STREQUAL doc_name_b)
    message(FATAL_ERROR "Failing Test case: source doc names collide for same-basename files.")
endif()

# and: a source outside the component directory falls back to its basename
_spl_source_doc_name(doc_name_ext "${CMAKE_CURRENT_LIST_DIR}/other/bar.c" "${CMAKE_CURRENT_LIST_DIR}/component")
if(NOT doc_name_ext STREQUAL "bar.c")
    message(FATAL_ERROR "Failing Test case: expected 'bar.c' but got '${doc_name_ext}'.")
endif()

# ## test: _spl_clanguru_docs_options (Jinja raw tags are optional) #########
# given the default configuration

# when
_spl_clanguru_docs_options(clanguru_default_options)

# then: listings keep their Jinja raw tags, as before the option existed
if(NOT clanguru_default_options STREQUAL "--format;rst;--jinja-raw-tags")
    message(FATAL_ERROR "Failing Test case: expected '--format;rst;--jinja-raw-tags' but got '${clanguru_default_options}'.")
endif()

# given a project that renders no document through Jinja
set(SPL_SOURCE_DOCS_JINJA_RAW_TAGS OFF)

# when
_spl_clanguru_docs_options(clanguru_plain_options)

# then
if(NOT clanguru_plain_options STREQUAL "--format;rst")
    message(FATAL_ERROR "Failing Test case: expected '--format;rst' but got '${clanguru_plain_options}'.")
endif()

# cleanup
unset(SPL_SOURCE_DOCS_JINJA_RAW_TAGS)

# ## test: _spl_sphinx_build_command (variant data file per build shape) #########
# given a project that configures no variant data file
set(AUTOCONF_JSON /build/kconfig/autoconf.json)

# when
_spl_sphinx_build_command(sphinx_plain_command SHAPE reports CONFIG /build/reports/config.json OUTPUT_DIR /build/reports/html)

# then: the command is exactly the one the targets have always run
set(expected_sphinx_plain_command
    ${CMAKE_COMMAND} -E env
    SPHINX_BUILD_CONFIGURATION_FILE=/build/reports/config.json
    AUTOCONF_JSON_FILE=/build/kconfig/autoconf.json
    VARIANT=mytestvariant
    -- sphinx-build -E -b html ${PROJECT_SOURCE_DIR} /build/reports/html
)
if(NOT sphinx_plain_command STREQUAL expected_sphinx_plain_command)
    message(FATAL_ERROR "Failing Test case: expected '${expected_sphinx_plain_command}' but got '${sphinx_plain_command}'.")
endif()

# given a variant data file for each build shape
set(SPL_VARIANT_DATA_FILE_DOCS /variants/docs.json)
set(SPL_VARIANT_DATA_FILE_REPORTS /variants/reports.json)

# when
_spl_sphinx_build_command(sphinx_docs_command SHAPE docs CONFIG /build/docs/config.json OUTPUT_DIR /build/docs/html)
_spl_sphinx_build_command(sphinx_reports_command SHAPE reports CONFIG /build/reports/config.json OUTPUT_DIR /build/reports/html)

# then: each build is given its own file, and only that one, as a sphinx-build
# option in front of the source and output directories
if(NOT sphinx_docs_command MATCHES ";-D;needs_variant_data_file=/variants/docs\\.json;[^;]+;/build/docs/html$" OR sphinx_docs_command MATCHES "reports\\.json")
    message(FATAL_ERROR "Failing Test case: the docs build must get the docs variant data file only, got '${sphinx_docs_command}'.")
endif()

if(NOT sphinx_reports_command MATCHES ";-D;needs_variant_data_file=/variants/reports\\.json;[^;]+;/build/reports/html$" OR sphinx_reports_command MATCHES "docs\\.json")
    message(FATAL_ERROR "Failing Test case: the reports build must get the reports variant data file only, got '${sphinx_reports_command}'.")
endif()

# cleanup
unset(AUTOCONF_JSON)
unset(SPL_VARIANT_DATA_FILE_DOCS)
unset(SPL_VARIANT_DATA_FILE_REPORTS)

# ## test: _spl_sphinx_source_dir and _spl_sphinx_relative_path #########
# given the default configuration

# when
_spl_sphinx_source_dir(default_sphinx_source_dir)
_spl_sphinx_relative_path(default_reports_path "${PROJECT_BINARY_DIR}/components/x/reports")

# then: Sphinx reads the project root, as before the option existed
if(NOT default_sphinx_source_dir STREQUAL PROJECT_SOURCE_DIR)
    message(FATAL_ERROR "Failing Test case: expected '${PROJECT_SOURCE_DIR}' but got '${default_sphinx_source_dir}'.")
endif()

file(RELATIVE_PATH expected_default_reports_path "${PROJECT_SOURCE_DIR}" "${PROJECT_BINARY_DIR}/components/x/reports")
if(NOT default_reports_path STREQUAL expected_default_reports_path)
    message(FATAL_ERROR "Failing Test case: expected '${expected_default_reports_path}' but got '${default_reports_path}'.")
endif()

# given a project that keeps its documents in a docs folder
set(SPL_SPHINX_SOURCE_DIR docs)

# when
_spl_sphinx_source_dir(docs_sphinx_source_dir)
_spl_sphinx_relative_path(docs_relative_path "${PROJECT_SOURCE_DIR}/docs/doc/index.md")
_spl_sphinx_build_command(docs_sphinx_command SHAPE docs CONFIG /build/docs/config.json OUTPUT_DIR /build/docs/html)

# then: the folder is resolved against the project root, paths are named from it,
# and sphinx-build reads it instead of the project root
if(NOT docs_sphinx_source_dir STREQUAL "${PROJECT_SOURCE_DIR}/docs")
    message(FATAL_ERROR "Failing Test case: expected '${PROJECT_SOURCE_DIR}/docs' but got '${docs_sphinx_source_dir}'.")
endif()

if(NOT docs_relative_path STREQUAL "doc/index.md")
    message(FATAL_ERROR "Failing Test case: expected 'doc/index.md' but got '${docs_relative_path}'.")
endif()

if(NOT "${PROJECT_SOURCE_DIR}/docs" IN_LIST docs_sphinx_command OR "${PROJECT_SOURCE_DIR}" IN_LIST docs_sphinx_command)
    message(FATAL_ERROR "Failing Test case: sphinx-build must read '${PROJECT_SOURCE_DIR}/docs', got '${docs_sphinx_command}'.")
endif()

# cleanup
unset(SPL_SPHINX_SOURCE_DIR)

# ## test: SPL_SPHINX_BINARY_DIR (generated pages keep stable document names) #########
# given a project that reaches the binary directory through `generated` in its source tree
set(SPL_SPHINX_BINARY_DIR generated)

# when
_spl_sphinx_relative_path(alias_reports_path "${PROJECT_BINARY_DIR}/components/x/reports")
_spl_sphinx_relative_path(alias_binary_dir_path "${PROJECT_BINARY_DIR}")
_spl_sphinx_relative_path(alias_source_path "${PROJECT_SOURCE_DIR}/component/doc")
_spl_sphinx_binary_dir_check(alias_check)

# then: paths inside the binary directory are named through it, other paths are not touched
if(NOT alias_reports_path STREQUAL "generated/components/x/reports")
    message(FATAL_ERROR "Failing Test case: expected 'generated/components/x/reports' but got '${alias_reports_path}'.")
endif()

if(NOT alias_binary_dir_path STREQUAL "generated")
    message(FATAL_ERROR "Failing Test case: expected 'generated' but got '${alias_binary_dir_path}'.")
endif()

if(NOT alias_source_path STREQUAL "component/doc")
    message(FATAL_ERROR "Failing Test case: expected 'component/doc' but got '${alias_source_path}'.")
endif()

# and: a documentation build checks the path before running Sphinx
if(NOT alias_check MATCHES "^COMMAND;.*check_sphinx_binary_dir\\.cmake$")
    message(FATAL_ERROR "Failing Test case: expected a COMMAND running check_sphinx_binary_dir.cmake but got '${alias_check}'.")
endif()

# given the default configuration
unset(SPL_SPHINX_BINARY_DIR)

# when
_spl_sphinx_binary_dir_check(default_check)

# then: nothing is added to the documentation build
if(NOT default_check STREQUAL "")
    message(FATAL_ERROR "Failing Test case: expected no check but got '${default_check}'.")
endif()

# ## test: check_sphinx_binary_dir.cmake #########
set(check_sphinx_binary_dir_script ${CMAKE_CURRENT_LIST_DIR}/../../../src/spl_core/check_sphinx_binary_dir.cmake)

# when the path leads to the binary directory being built
execute_process(
    COMMAND ${CMAKE_COMMAND} -DSPL_SPHINX_BINARY_DIR=${PROJECT_BINARY_DIR} -DSPL_BINARY_DIR=${PROJECT_BINARY_DIR} -P ${check_sphinx_binary_dir_script}
    RESULT_VARIABLE check_same_dir_result OUTPUT_QUIET ERROR_QUIET
)

# then
if(NOT check_same_dir_result EQUAL 0)
    message(FATAL_ERROR "Failing Test case: the check must pass when the path leads to the binary directory.")
endif()

# when it leads somewhere else, as after configuring another build directory
execute_process(
    COMMAND ${CMAKE_COMMAND} -DSPL_SPHINX_BINARY_DIR=${PROJECT_SOURCE_DIR} -DSPL_BINARY_DIR=${PROJECT_BINARY_DIR} -P ${check_sphinx_binary_dir_script}
    RESULT_VARIABLE check_other_dir_result OUTPUT_QUIET ERROR_QUIET
)

# then
if(check_other_dir_result EQUAL 0)
    message(FATAL_ERROR "Failing Test case: the check must fail when the path leads to another directory.")
endif()

# when it does not exist
execute_process(
    COMMAND ${CMAKE_COMMAND} -DSPL_SPHINX_BINARY_DIR=${PROJECT_BINARY_DIR}/does_not_exist -DSPL_BINARY_DIR=${PROJECT_BINARY_DIR} -P ${check_sphinx_binary_dir_script}
    RESULT_VARIABLE check_missing_dir_result OUTPUT_QUIET ERROR_QUIET
)

# then
if(check_missing_dir_result EQUAL 0)
    message(FATAL_ERROR "Failing Test case: the check must fail when the path does not exist.")
endif()

# ## test: _spl_get_absolute_path #########
# when
_spl_get_absolute_path(absolute_path "${PROJECT_SOURCE_DIR}/some_dir")

# then
set(expected_path tests/cmake/common.cmake/some_dir)
string(FIND "${absolute_path}" "${expected_path}" out)

if(NOT "${out}" GREATER 0)
    message(FATAL_ERROR "Failing Test case: ${absolute_path} does not contain ${expected_path}.")
endif()

# when
_spl_get_absolute_path(absolute_path "${PROJECT_BINARY_DIR}/some_output")

# then
set(expected_path out/test_cmake/common.cmake/some_output)
string(FIND "${absolute_path}" "${expected_path}" out)

if(NOT "${out}" GREATER 0)
    message(FATAL_ERROR "Failing Test case: ${absolute_path} does not contain ${expected_path}.")
endif()

# ## test: spl_add_source #########
# given
set(source_file src/some_source_file.c)
set(other_source_file src/some_other_source_file.c)

# when
spl_add_source(${source_file})
spl_add_source(${other_source_file})

# then
_spl_get_absolute_path(expected_source_file "${source_file}")
_spl_get_absolute_path(expected_other_source_file "${other_source_file}")
_spl_get_absolute_path(unexpected_source_file "not_expected.c")

if(NOT expected_source_file IN_LIST SOURCES)
    message(FATAL_ERROR "Failing Test case: ${expected_source_file} not found inside ${SOURCES}.")
endif()

if(NOT expected_other_source_file IN_LIST SOURCES)
    message(FATAL_ERROR "Failing Test case: ${expected_other_source_file} not found inside ${SOURCES}.")
endif()

if(unexpected_source_file IN_LIST SOURCES)
    message(FATAL_ERROR "Failing Test case: ${unexpected_source_file} not found inside ${SOURCES}.")
endif()

# cleanup
unset(SOURCES)

# ## test: spl_add_test_source #########

# given
set(test_source_file test/some_test_source_file.c)
set(other_test_source_file test/some_other_test_source_file.c)

# when
spl_add_test_source(${test_source_file})
spl_add_test_source(${other_test_source_file})

# then
_spl_get_absolute_path(expected_test_source_file "${test_source_file}")
_spl_get_absolute_path(expected_other_test_source_file "${other_test_source_file}")
_spl_get_absolute_path(unexpected_test_source_file "not_expected.c")

if(NOT expected_test_source_file IN_LIST TEST_SOURCES)
    message(FATAL_ERROR "Failing Test case: ${expected_test_source_file} not found inside ${TEST_SOURCES}.")
endif()

if(NOT expected_other_test_source_file IN_LIST TEST_SOURCES)
    message(FATAL_ERROR "Failing Test case: ${expected_other_test_source_file} not found inside ${TEST_SOURCES}.")
endif()

if(unexpected_test_source_file IN_LIST TEST_SOURCES)
    message(FATAL_ERROR "Failing Test case: ${unexpected_test_source_file} not found inside ${TEST_SOURCES}.")
endif()

# cleanup
unset(TEST_SOURCES)

# ## test: spl_add_provided_interface #########
# given
set(provided_interface_dir src/provided/interface_dir)
set(other_provided_interface_dir src/other/provided_interface_dir)

# when
spl_add_provided_interface(${provided_interface_dir})
spl_add_provided_interface(${other_provided_interface_dir})

# then
_spl_get_absolute_path(expected_provided_interface_dir "${provided_interface_dir}")
_spl_get_absolute_path(expected_other_provided_interface_dir "${other_provided_interface_dir}")

if(NOT expected_provided_interface_dir IN_LIST PROVIDED_INTERFACES)
    message(FATAL_ERROR "Failing Test case: ${expected_provided_interface_dir} not found inside ${PROVIDED_INTERFACES}.")
endif()

if(NOT expected_other_provided_interface_dir IN_LIST PROVIDED_INTERFACES)
    message(FATAL_ERROR "Failing Test case: ${expected_other_provided_interface_dir} not found inside ${PROVIDED_INTERFACES}.")
endif()

# cleanup
unset(PROVIDED_INTERFACES)

# ## test: spl_add_required_interface #########
# given
set(required_component src/required_component)
set(other_required_component src/other_required_component)

# when
spl_add_required_interface(${required_component})
spl_add_required_interface(${other_required_component})

# then
_spl_slash_to_underscore(expected_required_component ${required_component})
_spl_slash_to_underscore(expected_other_required_component ${other_required_component})

if(NOT expected_required_component IN_LIST REQUIRED_INTERFACES)
    message(FATAL_ERROR "Failing Test case: ${expected_required_component} not found inside ${REQUIRED_INTERFACES}.")
endif()

if(NOT expected_other_required_component IN_LIST REQUIRED_INTERFACES)
    message(FATAL_ERROR "Failing Test case: ${expected_other_required_component} not found inside ${REQUIRED_INTERFACES}.")
endif()

# cleanup
unset(REQUIRED_INTERFACES)

# ## test: spl_add_component ###############

# given
set(some_file src/some_file.c)
set(some_other_file src/some_other_file.c)

# when
spl_add_component(component)
spl_add_component(some_other_component)
set_target_properties(component PROPERTIES LINKER_LANGUAGE C)

# then
if(NOT "component" IN_LIST COMPONENT_NAMES)
    message(FATAL_ERROR "Failing Test case: component not found inside ${COMPONENT_NAMES}.")
endif()

# cleanup
unset(SOURCES)
unset(COMPONENT_NAMES)

# ## test: spl_add_named_component ############

# given
# some external component with relative path
set(some_external_component external_package/some_external_component)

# another external component with absolute path
set(another_external_component ${CMAKE_CURRENT_LIST_DIR}/external_package/another_external_component)

# when
spl_add_named_component(some_external_component)
spl_add_named_component(another_external_component)

# then
# Note: component names are now derived from the path when a create component NAME is specified
foreach(expected_component IN ITEMS some_external_component another_external_component_name)
    if(NOT "${expected_component}" IN_LIST COMPONENT_NAMES)
        message(FATAL_ERROR "Failing Test case: ${expected_component} not found inside ${COMPONENT_NAMES}.")
    endif()
endforeach()

# ## test: _spl_create_build_info_file (tests are written in test_cmake.py)#####
_spl_create_build_info_file()

# cleanup
unset(SOURCES)
unset(COMPONENT_NAMES)

# ## test: _spl_set_test_compile_and_link_options #########
message(STATUS "CMAKE_C_COMPILER_ID: ${CMAKE_C_COMPILER_ID}")
message(STATUS "CMAKE_C_COMPILER_VERSION: ${CMAKE_C_COMPILER_VERSION}")
message(STATUS "CMAKE_CXX_COMPILER_ID: ${CMAKE_CXX_COMPILER_ID}")
message(STATUS "CMAKE_CXX_COMPILER_VERSION: ${CMAKE_CXX_COMPILER_VERSION}")

# Act
_spl_set_test_compile_and_link_options("GNU" "13.1.0")

# Assert
if(NOT "-ggdb" IN_LIST TEST_COMPILE_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -ggdb not found inside ${TEST_COMPILE_OPTIONS}.")
endif()

if(NOT "-ggdb" IN_LIST COMPONENT_TEST_COMPILE_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -ggdb not found inside ${COMPONENT_TEST_COMPILE_OPTIONS}.")
endif()

if("-fcondition-coverage" IN_LIST COMPONENT_TEST_COMPILE_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -fcondition-coverage found inside ${COMPONENT_TEST_COMPILE_OPTIONS}.")
endif()

if(NOT "-ggdb" IN_LIST TEST_LINK_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -ggdb not found inside ${TEST_LINK_OPTIONS}.")
endif()

if("-fcondition-coverage" IN_LIST TEST_LINK_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -fcondition-coverage found inside ${TEST_LINK_OPTIONS}.")
endif()

# Act
_spl_set_test_compile_and_link_options("GNU" "14.1.0")

# Assert
if("-fcondition-coverage" IN_LIST COMPONENT_TEST_COMPILE_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -fcondition-coverage found inside ${COMPONENT_TEST_COMPILE_OPTIONS}.")
endif()

if("-fcondition-coverage" IN_LIST TEST_LINK_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -fcondition-coverage found inside ${TEST_LINK_OPTIONS}.")
endif()

# Act
_spl_set_test_compile_and_link_options("GNU" "14.2.0")

# Assert
if(NOT "-fcondition-coverage" IN_LIST COMPONENT_TEST_COMPILE_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -fcondition-coverage not found inside ${COMPONENT_TEST_COMPILE_OPTIONS}.")
endif()

if(NOT "-fcondition-coverage" IN_LIST TEST_LINK_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -fcondition-coverage not found inside ${TEST_LINK_OPTIONS}.")
endif()

# Act
_spl_set_test_compile_and_link_options("GNU" "14.2.1")

# Assert
if("-fcondition-coverage" IN_LIST TEST_COMPILE_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -fcondition-coverage found inside ${TEST_COMPILE_OPTIONS}.")
endif()

if(NOT "-fcondition-coverage" IN_LIST COMPONENT_TEST_COMPILE_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -fcondition-coverage not found inside ${COMPONENT_TEST_COMPILE_OPTIONS}.")
endif()

if(NOT "-fcondition-coverage" IN_LIST TEST_LINK_OPTIONS)
    message(FATAL_ERROR "Failing Test case: -fcondition-coverage not found inside ${TEST_LINK_OPTIONS}.")
endif()

# Act
# The next macro call fails. This is an explorative test to show that compiler id "BIBI" is not supported.
# Mocking of method "message()" sadly does not work.
# _spl_set_test_compile_and_link_options("BIBI" "1.2.3")
