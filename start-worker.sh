#!/bin/bash

echo "Starting Hadoop Worker Node..."

# Wait for master to be ready
echo "Waiting for NameNode to be ready..."
sleep 15

# Start DataNode
echo "Starting DataNode..."
$HADOOP_HOME/bin/hdfs --daemon start datanode

# Start NodeManager
echo "Starting NodeManager..."
$HADOOP_HOME/bin/yarn --daemon start nodemanager

echo "Worker services started!"

# Keep container running
tail -f /dev/null
