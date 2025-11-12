#!/bin/bash
# Teste 5: Impacto da Memória dos Containers MapReduce

RESULTS_FILE="tests/results/test5_results.txt"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

collect_mr_metrics() {
    local test_name=$1
    echo_section "Coletando Métricas MapReduce - $test_name"

    echo "=== $test_name ===" >> $RESULTS_FILE
    echo "Timestamp: $(date)" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Configuração MapReduce
    echo "Configuração MapReduce:" >> $RESULTS_FILE
    docker exec hadoop-master cat /opt/hadoop/etc/hadoop/mapred-site.xml | grep -A 2 "memory" >> $RESULTS_FILE 2>&1
    echo "" >> $RESULTS_FILE

    # Aplicações
    echo "Status das Aplicações:" >> $RESULTS_FILE
    docker exec hadoop-master yarn application -list -appStates ALL | tail -10 >> $RESULTS_FILE 2>&1
    echo "" >> $RESULTS_FILE

    echo "----------------------------------------" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
}

apply_mapreduce_memory() {
    local map_memory=$1
    local reduce_memory=$2
    local am_memory=$3
    echo_info "Aplicando memória MapReduce: Map=${map_memory}MB, Reduce=${reduce_memory}MB, AM=${am_memory}MB"

    cp hadoop-config/mapred-site.xml hadoop-config/mapred-site.xml.backup

    cat > tests/configurations/test5/mapred-site-${map_memory}.xml <<EOF
<?xml version="1.0"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>

    <property>
        <name>mapreduce.map.memory.mb</name>
        <value>$map_memory</value>
        <description>TESTE: Memória para Map tasks</description>
    </property>

    <property>
        <name>mapreduce.reduce.memory.mb</name>
        <value>$reduce_memory</value>
        <description>TESTE: Memória para Reduce tasks</description>
    </property>

    <property>
        <name>yarn.app.mapreduce.am.resource.mb</name>
        <value>$am_memory</value>
        <description>TESTE: Memória para Application Master</description>
    </property>

    <property>
        <name>mapreduce.map.java.opts</name>
        <value>-Xmx$((map_memory * 80 / 100))m</value>
    </property>

    <property>
        <name>mapreduce.reduce.java.opts</name>
        <value>-Xmx$((reduce_memory * 80 / 100))m</value>
    </property>

    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>hadoop-master:10020</value>
    </property>

    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>0.0.0.0:19888</value>
    </property>

    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=/opt/hadoop</value>
    </property>
</configuration>
EOF

    cp tests/configurations/test5/mapred-site-${map_memory}.xml hadoop-config/mapred-site.xml

    docker-compose restart hadoop-master hadoop-worker1 hadoop-worker2
    sleep 40
}

run_mapreduce_job() {
    local job_name=$1
    echo_info "Executando job MapReduce: $job_name"

    # Preparar dados
    docker exec hadoop-master bash -c "
        echo 'MapReduce memory test data' > /tmp/mrtest.txt
        for i in {1..2000}; do
            echo 'Line \$i: Testing MapReduce memory allocation impact on job performance and resource utilization patterns in distributed computing environments' >> /tmp/mrtest.txt
        done

        hdfs dfs -rm -r -f /test_mr_memory
        hdfs dfs -mkdir -p /test_mr_memory/input
        hdfs dfs -put -f /tmp/mrtest.txt /test_mr_memory/input/
    " 2>/dev/null

    # Executar job com medição de tempo
    echo "" >> $RESULTS_FILE
    echo "Executando Job: $job_name" >> $RESULTS_FILE
    START_TIME=\$(date +%s)

    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_mr_memory/output
        timeout 120 hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
            wordcount \
            /test_mr_memory/input \
            /test_mr_memory/output
    " >> $RESULTS_FILE 2>&1

    RESULT=$?
    END_TIME=\$(date +%s)
    DURATION=\$((END_TIME - START_TIME))

    echo "" >> $RESULTS_FILE
    if [ $RESULT -eq 0 ]; then
        echo "Job Status: SUCCESS" >> $RESULTS_FILE
    elif [ $RESULT -eq 124 ]; then
        echo "Job Status: TIMEOUT (>120s)" >> $RESULTS_FILE
    else
        echo "Job Status: FAILED (exit code: $RESULT)" >> $RESULTS_FILE
    fi
    echo "Tempo de execução: ${DURATION}s" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Verificar resultado
    docker exec hadoop-master hdfs dfs -cat /test_mr_memory/output/part-r-00000 2>/dev/null | head -5 >> $RESULTS_FILE || echo "Sem saída" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
}

test_baseline() {
    echo_section "TESTE BASELINE - Map=512MB, Reduce=512MB"

    echo "TESTE 5: Impacto da Memória dos Containers MapReduce" > $RESULTS_FILE
    echo "Data: $(date)" >> $RESULTS_FILE
    echo "========================================" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    collect_mr_metrics "BASELINE (Map=512MB, Reduce=512MB)"
    run_mapreduce_job "baseline"

    echo_info "Baseline concluído!"
}

test_low() {
    echo_section "TESTE LOW - Map=256MB, Reduce=256MB"

    apply_mapreduce_memory 256 256 256
    collect_mr_metrics "TEST_LOW (Map=256MB, Reduce=256MB)"
    run_mapreduce_job "low_memory"

    echo_info "Teste LOW concluído!"
}

test_high() {
    echo_section "TESTE HIGH - Map=1024MB, Reduce=1024MB"

    apply_mapreduce_memory 1024 1024 512
    collect_mr_metrics "TEST_HIGH (Map=1024MB, Reduce=1024MB)"
    run_mapreduce_job "high_memory"

    echo_info "Teste HIGH concluído!"
}

restore_config() {
    echo_section "Restaurando Configuração Original"

    if [ -f hadoop-config/mapred-site.xml.backup ]; then
        mv hadoop-config/mapred-site.xml.backup hadoop-config/mapred-site.xml
        docker-compose restart hadoop-master hadoop-worker1 hadoop-worker2
        sleep 40
        echo_info "Configuração restaurada!"
    fi
}

case "$1" in
    baseline)
        test_baseline
        ;;
    test_low)
        test_low
        ;;
    test_high)
        test_high
        ;;
    restore)
        restore_config
        ;;
    all)
        test_baseline
        test_low
        test_high
        restore_config
        ;;
    *)
        echo "Uso: $0 {baseline|test_low|test_high|restore|all}"
        echo ""
        echo "  baseline  - Teste com configuração padrão (512MB)"
        echo "  test_low  - Teste com memória baixa (256MB)"
        echo "  test_high - Teste com memória alta (1024MB)"
        echo "  restore   - Restaurar configuração original"
        echo "  all       - Executar todos os testes"
        exit 1
        ;;
esac

echo ""
echo_section "Resultados salvos em: $RESULTS_FILE"
