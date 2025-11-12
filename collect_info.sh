#!/bin/bash
# Script para coletar informações do cluster para entrega do trabalho

OUTPUT_FILE="cluster_info.txt"

echo "======================================" > $OUTPUT_FILE
echo "INFORMAÇÕES DO CLUSTER HADOOP" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "Data: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

echo "Coletando informações do cluster..."

# Status dos containers
echo "======================================" >> $OUTPUT_FILE
echo "1. STATUS DOS CONTAINERS" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
docker-compose ps >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# Informações do HDFS
echo "======================================" >> $OUTPUT_FILE
echo "2. RELATÓRIO DO HDFS" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
docker exec hadoop-master hdfs dfsadmin -report >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# NodeManagers ativos
echo "======================================" >> $OUTPUT_FILE
echo "3. NODEMANAGERS ATIVOS" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
docker exec hadoop-master yarn node -list >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# Processos no Master
echo "======================================" >> $OUTPUT_FILE
echo "4. PROCESSOS NO NÓ MASTER" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
docker exec hadoop-master jps >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# Processos no Worker 1
echo "======================================" >> $OUTPUT_FILE
echo "5. PROCESSOS NO WORKER 1" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
docker exec hadoop-worker1 jps >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# Processos no Worker 2
echo "======================================" >> $OUTPUT_FILE
echo "6. PROCESSOS NO WORKER 2" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
docker exec hadoop-worker2 jps >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# Estrutura de diretórios HDFS
echo "======================================" >> $OUTPUT_FILE
echo "7. ESTRUTURA DO HDFS" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
docker exec hadoop-master hdfs dfs -ls -R / >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# Aplicações YARN recentes
echo "======================================" >> $OUTPUT_FILE
echo "8. APLICAÇÕES YARN (ÚLTIMAS 10)" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
docker exec hadoop-master yarn application -list -appStates ALL | head -20 >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# Arquivos de configuração
echo "======================================" >> $OUTPUT_FILE
echo "9. ARQUIVOS DE CONFIGURAÇÃO" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

echo "--- core-site.xml ---" >> $OUTPUT_FILE
cat hadoop-config/core-site.xml >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

echo "--- hdfs-site.xml ---" >> $OUTPUT_FILE
cat hadoop-config/hdfs-site.xml >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

echo "--- yarn-site.xml ---" >> $OUTPUT_FILE
cat hadoop-config/yarn-site.xml >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

echo "--- mapred-site.xml ---" >> $OUTPUT_FILE
cat hadoop-config/mapred-site.xml >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

echo "--- workers ---" >> $OUTPUT_FILE
cat hadoop-config/workers >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# URLs das interfaces web
echo "======================================" >> $OUTPUT_FILE
echo "10. INTERFACES WEB DISPONÍVEIS" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE
echo "HDFS NameNode UI: http://localhost:9870" >> $OUTPUT_FILE
echo "YARN ResourceManager UI: http://localhost:8088" >> $OUTPUT_FILE
echo "MapReduce JobHistory: http://localhost:19888" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

echo "======================================" >> $OUTPUT_FILE
echo "FIM DO RELATÓRIO" >> $OUTPUT_FILE
echo "======================================" >> $OUTPUT_FILE

echo "✓ Informações coletadas com sucesso!"
echo "✓ Arquivo gerado: $OUTPUT_FILE"
echo ""
echo "Próximos passos para a entrega:"
echo "1. Tire screenshots das interfaces web:"
echo "   - http://localhost:9870 (HDFS)"
echo "   - http://localhost:8088 (YARN)"
echo "   - http://localhost:19888 (JobHistory)"
echo ""
echo "2. Execute o exemplo WordCount:"
echo "   docker cp examples/wordcount hadoop-master:/tmp/"
echo "   docker exec hadoop-master bash -c 'cd /tmp/wordcount && chmod +x *.py *.sh && ./run_wordcount.sh'"
echo ""
echo "3. Tire screenshot dos resultados do WordCount"
echo ""
echo "4. Compile tudo em um relatório com:"
echo "   - Este arquivo: $OUTPUT_FILE"
echo "   - Screenshots das interfaces"
echo "   - Arquivos de configuração (pasta hadoop-config/)"
echo "   - docker-compose.yml"
echo "   - README.md com explicações"
