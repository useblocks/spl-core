# Stops a docs or reports build when SPL_SPHINX_BINARY_DIR does not lead to the binary
# directory being built.
#
# The path is usually a link that the project re-points whenever it configures a
# build directory. If another build directory was configured since, the link leads
# to that build's output, and Sphinx would read its generated pages as if they
# belonged to this build, without a warning.
#
# Called in script mode by the docs and reports targets:
#
#     cmake -DSPL_SPHINX_BINARY_DIR=<path> -DSPL_BINARY_DIR=<binary dir> -P check_sphinx_binary_dir.cmake

# A path that does not exist on disk is not a link: the project reaches the binary
# directory another way, for example through a sphinx-mounts mount that each build
# names in the options of its own runs. There is nothing to compare.
if(NOT EXISTS "${SPL_SPHINX_BINARY_DIR}")
    return()
endif()

file(REAL_PATH "${SPL_SPHINX_BINARY_DIR}" _resolved)
file(REAL_PATH "${SPL_BINARY_DIR}" _expected)

if(NOT _resolved STREQUAL _expected)
    message(FATAL_ERROR
        "SPL_SPHINX_BINARY_DIR ${SPL_SPHINX_BINARY_DIR} leads to ${_resolved}, "
        "but this build writes to ${_expected}. Configure this build directory again, "
        "or point the path at it, before building its documentation.")
endif()
