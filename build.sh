#!/bin/bash

THIS_DIR=$(dirname "$(realpath $0)")

# TODO create gitlab job
# Want stack for these datawave versions:
# - 2.10.0-SNAPSHOT
# - 2.8.8
# - 2.8.8-hadoop3
# TODO build images for the following versions:
# - 1.9.2

# NOTE: REGISTRY_URL is used to specify where to push the built images...must have trailing '/'
source ${THIS_DIR}/util/logging.sh

ACCUMULO="accumulo"
HELP="help"

ACCUMULO_VERSION="1.9.2"

header "Docker Build Utility"

function usage() {
    echo "Usage: $0 [-v|--version ver1 ver2 ...] [-p|--push] [ ${HELP} ]"
    echo -e "\t${HELP} - to see this message"
    echo "Options:"
    echo -e "\t-v - What versions to tag the images as"
    echo -e "\t-p - Pass this option if you want to push to the REGISTRY"
    exit 1
}

function build_failed() {
    error_exit "Build of $1 failed"
}

function build_accumulo() {
    info "Building ${ACCUMULO} docker image"

    if ! docker build -t ${ACCUMULO} ${THIS_DIR}/${ACCUMULO}; then
        build_failed ${ACCUMULO}
    fi
    success "Completed building ${ACCUMULO} docker image"
}

function tag_images() {
    info "Tagging docker images as: [ ${IMAGE_VERSIONS[*]} ]"
    for v in "${IMAGE_VERSIONS[@]}"; do
        docker tag "${ACCUMULO}" "${REGISTRY_URL}${ACCUMULO}:$v" || error_exit "Failed to tag ${REGISTRY_URL}${ACCUMULO}:$v"
    done
    success "Completed tagging docker images"
}

function push_images() {
    info "Pushing docker images"
    for v in "${IMAGE_VERSIONS[@]}"; do
        docker push "${REGISTRY_URL}${ACCUMULO}:$v" || error_exit "Failed to push ${REGISTRY_URL}${ACCUMULO}:$v"
    done
    success "Completed pushing docker images"
}

if [[ $* =~ ${HELP} ]]; then
    usage
fi

# From: https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f
while (( "$#" )); do
    case "$1" in
        -v|--version )
            if [ -z "$2" ]; then
                error_exit "Argument required for $1"
            fi
            shift 1

            while [ -n "$1" ] && [ "${1:0:1}" != "-" ]; do
                IMAGE_VERSIONS+=("$1")
                shift 1
            done
            ;;
        -p|--push )
            PUSH="true"
            ;;
        -? )
            usage
            ;;
        -*|--*=) # unsupported flags
            error_exit "Unsupported flag $1"
            ;;
        *)
            error_exit "Unsupported positional argument: $1"
            ;;
    esac
done

build_accumulo

# Set one image version as the installed Accumulo version
IMAGE_VERSIONS+=( "${ACCUMULO_VERSION}" )
if [[ -n ${IMAGE_VERSIONS[*]} ]]; then
    tag_images
fi

if [[ "${PUSH}" == "true" ]]; then
    push_images
fi
