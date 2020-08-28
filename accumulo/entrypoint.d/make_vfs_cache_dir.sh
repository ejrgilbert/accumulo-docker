#!/bin/bash

VFS_CACHE_DIR=$(xmllint --xpath 'string(//configuration/property[name="general.vfs.cache.dir"]/value)' "${ACCUMULO_HOME}/conf/accumulo-site.xml")
if [[ "${VFS_CACHE_DIR}" == "" ]]; then
    echo "'general.vfs.cache.dir' not used, continuing..."
    exit 0
fi

if ! mkdir -p "${VFS_CACHE_DIR}"; then
    echo "Failed to create the vfs-cache directory: ${VFS_CACHE_DIR}"
    exit 1
fi

chown -R accumulo:accumulo "${VFS_CACHE_DIR}"
