#!/bin/bash

# Run all startup scripts
/opt/docker_utils/run-parts.sh
# Wait until necessary services are available before continuing
/opt/docker_utils/wait.sh

if nodeattr -v "$(hostname -s)" accumulo_master; then
    # Create HDFS classpath directories
    GENERAL_CLASSPATH=$(xmllint --xpath 'string(//configuration/property[name="general.vfs.classpaths"]/value)' "${ACCUMULO_HOME}/conf/accumulo-site.xml")
    GENERAL_CLASSPATH=${GENERAL_CLASSPATH%/*}
    DATAWAVE_CLASSPATH=$(xmllint --xpath 'string(//configuration/property[name="general.vfs.context.classpath.datawave"]/value)' "${ACCUMULO_HOME}/conf/accumulo-site.xml")
    DATAWAVE_CLASSPATH=${DATAWAVE_CLASSPATH%/*}
    runuser -l accumulo -c "hdfs dfs -mkdir -p ${GENERAL_CLASSPATH}" \
        || error "Failed to create ${GENERAL_CLASSPATH}"
    runuser -l datawave -c "hdfs dfs -mkdir -p ${DATAWAVE_CLASSPATH}" \
        || error "Failed to create ${DATAWAVE_CLASSPATH}"

    INSTANCE_VOLUMES=$(xmllint --xpath 'string(//configuration/property[name="instance.volumes"]/value)' "${ACCUMULO_HOME}/conf/accumulo-site.xml")
    hdfs dfs -chown -R accumulo "${INSTANCE_VOLUMES}" >/dev/null 2>&1

    INSTANCE_NAME=$(xmllint --xpath 'string(//configuration/property[name="instance.name"]/value)' "${ACCUMULO_HOME}/conf/accumulo-site.xml")

    if ! hdfs dfs -test -e hdfs://namenode:8020/accumulo/instance_id || [[ ! "$*" =~ "-persist" ]]; then
        # Only initialize zookeeper if it hasn't been initialized yet (data dir is empty) or
        # if the '-persist' option hasn't been passed to the container.
        echo "Deleting old accumulo data..."
        hadoop fs -rm -r "${INSTANCE_VOLUMES}" >/dev/null 2>&1

        echo "Sleeping for 5 seconds after deleting dir"
        sleep 5

        echo "Initializing accumulo"
        /usr/sbin/runuser -l accumulo -c "${ACCUMULO_HOME}/bin/accumulo init --instance-name ${INSTANCE_NAME} --password accumulo --clear-instance-name"
        echo "Init done..."
    fi

    /usr/sbin/runuser -l accumulo -c "${ACCUMULO_HOME}/bin/start-all.sh"
    echo "Finished starting up accumulo processes..."
fi

tail -F /keep/me/running >/dev/null 2>&1
