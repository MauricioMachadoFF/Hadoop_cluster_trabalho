#!/bin/bash

echo "Starting Hadoop Master Node..."

# Format NameNode if not already formatted
if [ ! -d "/hadoop/dfs/name/current" ]; then
  echo "Formatting NameNode..."
  $HADOOP_HOME/bin/hdfs namenode -format -force
fi

# Start NameNode
echo "Starting NameNode..."
$HADOOP_HOME/bin/hdfs --daemon start namenode

# Wait for NameNode to start
sleep 5

# Start ResourceManager
echo "Starting ResourceManager..."
$HADOOP_HOME/bin/yarn --daemon start resourcemanager
sleep 10

# Start JobHistory Server
echo "Starting JobHistory Server..."
$HADOOP_HOME/bin/mapred --daemon start historyserver
sleep 5

echo "Master services started. Checking status..."

# Show running processes
echo "=== HDFS Status ==="
$HADOOP_HOME/bin/hdfs dfsadmin -report 2>&1 | head -20 || true
sleep 2

echo ""
echo "=== YARN Status (waiting for ResourceManager...) ==="
# Wait for ResourceManager to be fully ready
for i in {1..30}; do
  if $HADOOP_HOME/bin/yarn node -list 2>&1 | grep -q "Total Nodes"; then
    echo "ResourceManager is ready!"
    $HADOOP_HOME/bin/yarn node -list
    break
  fi
  echo "Waiting for ResourceManager... ($i/30)"
  sleep 2
done

echo ""
echo "Master node is ready!"
echo "Web interfaces:"
echo "  - HDFS NameNode: http://localhost:9870"
echo "  - YARN ResourceManager: http://localhost:8088"
echo "  - MapReduce JobHistory: http://localhost:19888"

# Keep container running
tail -f /dev/null
