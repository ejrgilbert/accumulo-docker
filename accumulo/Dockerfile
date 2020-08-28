# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM base:1.0.0

ARG ACCUMULO_VERSION=1.9.2
ARG HADOOP_USER_NAME=accumulo
ARG ACCUMULO_FILE=""

ENV HADOOP_USER_NAME $HADOOP_USER_NAME

ARG ACCUMULO_DST=/opt/accumulo
ENV HADOOP_HOME /usr/lib/hadoop
ENV ZOOKEEPER_HOME /usr/lib/zookeeper
ENV ACCUMULO_HOME ${ACCUMULO_DST}/current
ENV ACCUMULO_CONF_DIR ${ACCUMULO_HOME}/conf
ENV ACCUMULO_LOG_DIR /srv/logs/accumulo

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk

ENV APACHE_DIST_URLS \
  https://www.apache.org/dyn/closer.cgi?action=download&filename= \
  https://www-us.apache.org/dist/ \
  https://www.apache.org/dist/ \
  https://archive.apache.org/dist/

COPY $ACCUMULO_FILE $HADOOP_FILE $ZOOKEEPER_FILE /tmp/

# Install hadoop and zookeeper
ADD *.repo /etc/yum.repos.d
RUN yum -y clean all && \
    yum -y install hadoop net-tools zookeeper-server && \
    yum -y clean all

# Install accumulo
RUN set -eux; \
  download() { \
    local f="$1"; shift; \
    local distFile="$1"; shift; \
    local success=; \
    local distUrl=; \
    for distUrl in $APACHE_DIST_URLS; do \
      if wget -nv -O "$f" "$distUrl$distFile"; then \
        success=1; \
        break; \
      fi; \
    done; \
    [ -n "$success" ]; \
  }; \
  \
  if [ -z "$ACCUMULO_FILE" ]; then \
    download "accumulo.tar.gz" "accumulo/$ACCUMULO_VERSION/accumulo-$ACCUMULO_VERSION-bin.tar.gz"; \
  else \
    cp "/tmp/$ACCUMULO_FILE" "accumulo.tar.gz"; \
  fi

RUN tar xzf accumulo.tar.gz -C /tmp/
RUN mv /tmp/accumulo-$ACCUMULO_VERSION ${ACCUMULO_DST} && \
    ln -s ${ACCUMULO_DST}/accumulo-$ACCUMULO_VERSION ${ACCUMULO_HOME}

RUN cp ${ACCUMULO_HOME}/conf/examples/2GB/native-standalone/* ${ACCUMULO_HOME}/conf/
RUN ${ACCUMULO_HOME}/bin/build_native_library.sh

# The below line is required for Accumulo 2.0 to work with ZK 3.5 & above.  This will not be needed for Accumulo 2.1
RUN sed -i 's/\${ZOOKEEPER_HOME}\/\*/\${ZOOKEEPER_HOME}\/\*\:\${ZOOKEEPER_HOME}\/lib\/\*/g' ${ACCUMULO_HOME}/conf/accumulo-env.sh

ADD accumulo-site.xml ${ACCUMULO_HOME}/conf
ADD generic_logger.xml ${ACCUMULO_HOME}/conf
ADD monitor_logger.xml ${ACCUMULO_HOME}/conf

# configure .bashrc and make needed dirs
ENV PATH "$PATH:$ACCUMULO_HOME/bin:$HADOOP_HOME/bin:$ZOOKEEPER_HOME/bin"
RUN echo "export DATAWAVE_HOME=${DATAWAVE_HOME}" >> ~root/.bashrc && \
    echo "export DATAWAVE_HOME=${DATAWAVE_HOME}" >> ~accumulo/.bashrc && \
    echo "export ACCUMULO_HOME=${ACCUMULO_HOME}" >> ~root/.bashrc && \
    echo "export ACCUMULO_HOME=${ACCUMULO_HOME}" >> ~accumulo/.bashrc && \
    echo "export HADOOP_HOME=${HADOOP_HOME}" >> ~root/.bashrc && \
    echo "export HADOOP_HOME=${HADOOP_HOME}" >> ~accumulo/.bashrc && \
    echo "export ZOOKEEPER_HOME=${ZOOKEEPER_HOME}" >> ~root/.bashrc && \
    echo "export ZOOKEEPER_HOME=${ZOOKEEPER_HOME}" >> ~accumulo/.bashrc && \
    echo "export ACCUMULO_CONF_DIR=\${ACCUMULO_HOME}/conf" >> ~root/.bashrc && \
    echo "export ACCUMULO_CONF_DIR=\${ACCUMULO_HOME}/conf" >> ~accumulo/.bashrc && \
    echo "export ACCUMULO_LOG_DIR=${ACCUMULO_LOG_DIR}" >> ~root/.bashrc && \
    echo "export ACCUMULO_LOG_DIR=${ACCUMULO_LOG_DIR}" >> ~accumulo/.bashrc && \
    echo "export JAVA_HOME=${JAVA_HOME}" >> ~root/.bashrc && \
    echo "export JAVA_HOME=${JAVA_HOME}" >> ~accumulo/.bashrc && \
    echo "export PATH=$PATH" >> ~root/.bashrc && \
    echo "export PATH=$PATH" >> ~accumulo/.bashrc && \
    usermod -a -G hadoop accumulo && \
    mkdir -p ${ACCUMULO_LOG_DIR} && \
    chown -R accumulo:hadoop ${ACCUMULO_LOG_DIR} && \
    chown -R accumulo:hadoop ${ACCUMULO_DST} && \
    chmod -R 750 ${ACCUMULO_DST} && \
    chmod 700 ${ACCUMULO_DST}/.ssh && \
    chmod 640 ${ACCUMULO_DST}/.ssh/authorized_keys && \
    chmod 644 ${ACCUMULO_DST}/.ssh/id_rsa.pub && \
    chmod 600 ${ACCUMULO_DST}/.ssh/id_rsa

# Add in entrypoint
ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
