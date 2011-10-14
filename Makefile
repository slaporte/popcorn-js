
PREFIX = .
BUILD_DIR = ${PREFIX}/build
DIST_DIR = ${PREFIX}/dist

# Version number used in naming release files. Defaults to git commit sha.
VERSION ?= $(shell git show -s --pretty=format:%h)

RHINO ?= java -jar ${BUILD_DIR}/js.jar

CLOSURE_COMPILER = ${BUILD_DIR}/google-compiler-20100917.jar
compile = @@${MINJAR} $(1) \
	                    --compilation_level SIMPLE_OPTIMIZATIONS \
	                    --js_output_file $(2)

# minify
MINJAR ?= java -jar ${CLOSURE_COMPILER}

# source
POPCORN_SRC = ${PREFIX}/popcorn.js

# distribution files
POPCORN_DIST = ${DIST_DIR}/popcorn.js
POPCORN_MIN = ${DIST_DIR}/popcorn.min.js

# Create a versioned license header for js files we ship
add_license = cat $(PREFIX)/LICENSE_HEADER | sed -e 's/@VERSION/${VERSION}/' > $(1).__hdr__ ; \
	                    cat $(1).__hdr__ $(1) >> $(1).__tmp__ ; rm -f $(1).__hdr__ ; \
	                    mv $(1).__tmp__ $(1)

# Create a version parameter for Popcorn
add_version = cat $(1) | sed -e 's/@VERSION/${VERSION}/' > $(1).__tmp__ ; \
	                    mv $(1).__tmp__ $(1)

# Run the file through jslint
run_lint = @@$(RHINO) build/jslint-check.js $(1)

all: setup popcorn min
	@@echo "Popcorn build complete.  To create a testing mirror, run: make testing."

check: lint

${DIST_DIR}:
	@@mkdir -p ${DIST_DIR}

popcorn: ${POPCORN_DIST}

${POPCORN_DIST}: $(POPCORN_SRC) | $(DIST_DIR)
	@@echo "Building" $(POPCORN_DIST)
	@@cp $(POPCORN_SRC) $(POPCORN_DIST)
	@@$(call add_license, $(POPCORN_DIST))
	@@$(call add_version, $(POPCORN_DIST))

min: setup ${POPCORN_MIN}

${POPCORN_MIN}: ${POPCORN_DIST}
	@@echo "Building" ${POPCORN_MIN}
	@@$(call compile, --js $(POPCORN_DIST), $(POPCORN_MIN))
	@@$(call add_license, $(POPCORN_MIN))
	@@$(call add_version, $(POPCORN_MIN))

lint:
	@@echo "Checking Popcorn against JSLint..."
	@@$(call run_lint,popcorn.js)

lint-core-tests:
	@@echo "Checking core unit tests against JSLint..."
	@@$(call run_lint,test/popcorn.unit.js)

clean:
	@@echo "Removing Distribution directory:" ${DIST_DIR}
	@@rm -rf ${DIST_DIR}

setup:
	@@echo "Updating submodules..."
	@@git submodule update --init
