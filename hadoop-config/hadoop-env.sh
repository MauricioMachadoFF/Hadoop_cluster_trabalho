#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Set Hadoop-specific environment variables here.

# The maximum amount of heap to use (Java -Xmx).  If no unit
# is provided, it will be converted to MB.  Daemons will
# prefer any Xmx setting in their respective _OPTS variable.
# There is no default; the JVM will autoscale based upon machine
# memory size.
export HADOOP_HEAPSIZE_MAX=1g

# The maximum amount of heap to use for YARN ResourceManager (Java -Xmx)
# Conservative settings for ARM Mac emulation environment
export YARN_RESOURCEMANAGER_HEAPSIZE=1024

# The maximum amount of heap to use for YARN NodeManager (Java -Xmx)
export YARN_NODEMANAGER_HEAPSIZE=768

# The maximum amount of heap to use for HDFS NameNode (Java -Xmx)
export HDFS_NAMENODE_HEAPSIZE=768

# The maximum amount of heap to use for HDFS DataNode (Java -Xmx)
export HDFS_DATANODE_HEAPSIZE=512

# Extra Java runtime options for all Hadoop commands. We don't support
# IPv6 yet/still, so by default the preference is set to IPv4.
export HADOOP_OPTS="-Djava.net.preferIPv4Stack=true"
