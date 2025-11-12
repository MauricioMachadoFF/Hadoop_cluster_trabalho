#!/bin/bash
# Teste 2: Impacto da Alocação de Memória YARN

RESULTS_FILE="tests/results/test2_results.txt"

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Função para coletar métricas YARN
collect_yarn_metrics() {
    local test_name=$1
    echo_section "Coletando Métricas YARN - $test_name"

    echo "=== $test_name ===" >> $RESULTS_FILE
    echo "Timestamp: $(date)" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Status dos NodeManagers
    echo "NodeManagers Status:" >> $RESULTS_FILE
    docker exec hadoop-master yarn node -list 2>/dev/null >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Recursos do cluster
    echo "Recursos do Cluster:" >> $RESULTS_FILE
    docker exec hadoop-master yarn node -status hadoop-worker1:8041 2>/dev/null >> $RESULTS_FILE
    docker exec hadoop-master yarn node -status hadoop-worker2:8041 2>/dev/null >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Aplicações
    echo "Aplicações Ativas:" >> $RESULTS_FILE
    docker exec hadoop-master yarn application -list 2>/dev/null >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    echo "----------------------------------------" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
}

# Função para aplicar configuração de memória
apply_memory_config() {
    local memory_mb=$1
    local max_allocation=$2
    echo_info "Aplicando configuração de memória: ${memory_mb}MB (max: ${max_allocation}MB)"

    # Backup
    cp hadoop-config/yarn-site.xml hadoop-config/yarn-site.xml.backup

    # Criar nova configuração
    cat > tests/configurations/test2/yarn-site-${memory_mb}.xml <<EOF
<?xml version="1.0"?>
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>hadoop-master</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>0.0.0.0:8088</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>hadoop-master:8032</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>$memory_mb</value>
        <description>TESTE: Memória total por NodeManager</description>
    </property>
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>256</value>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>$max_allocation</value>
        <description>TESTE: Memória máxima por container</description>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
    </property>
</configuration>
EOF

    # Aplicar configuração
    cp tests/configurations/test2/yarn-site-${memory_mb}.xml hadoop-config/yarn-site.xml

    # Restart cluster
    echo_info "Reiniciando cluster..."
    docker-compose restart hadoop-master hadoop-worker1 hadoop-worker2
    sleep 40
}

# Função para executar job de teste
run_test_job() {
    local job_name=$1
    echo_info "Executando job de teste: $job_name"

    # Criar dados de teste
    docker exec hadoop-master bash -c "
        echo 'Test data for memory impact analysis' > /tmp/memtest.txt
        for i in {1..1000}; do
            echo 'Line \$i: This is test data to evaluate memory allocation impact on job execution performance and resource utilization in YARN' >> /tmp/memtest.txt
        done

        hdfs dfs -rm -r -f /test_memory
        hdfs dfs -mkdir -p /test_memory/input
        hdfs dfs -put -f /tmp/memtest.txt /test_memory/input/
    " 2>/dev/null

    # Executar WordCount
    echo_info "Executando WordCount..."
    START_TIME=\$(date +%s)

    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_memory/output
        hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /test_memory/input /test_memory/output
    " 2>&1 | tee -a $RESULTS_FILE

    END_TIME=\$(date +%s)
    DURATION=\$((END_TIME - START_TIME))

    echo "" >> $RESULTS_FILE
    echo "Tempo de execução: ${DURATION}s" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
}

# Teste baseline
test_baseline() {
    echo_section "TESTE BASELINE - Memória = 2048MB"

    echo "TESTE 2: Impacto da Alocação de Memória YARN" > $RESULTS_FILE
    echo "Data: $(date)" >> $RESULTS_FILE
    echo "========================================" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    collect_yarn_metrics "BASELINE (Memory=2048MB)"
    run_test_job "baseline"

    echo_info "Baseline concluído!"
}

# Teste com memória baixa
test_low() {
    echo_section "TESTE LOW - Memória = 1024MB"

    apply_memory_config 1024 1024
    collect_yarn_metrics "TEST_LOW (Memory=1024MB)"
    run_test_job "low_memory"

    echo_info "Teste LOW concluído!"
}

# Teste com memória alta
test_high() {
    echo_section "TESTE HIGH - Memória = 4096MB"

    apply_memory_config 4096 4096
    collect_yarn_metrics "TEST_HIGH (Memory=4096MB)"
    run_test_job "high_memory"

    echo_info "Teste HIGH concluído!"
}

# Restaurar configuração
restore_config() {
    echo_section "Restaurando Configuração Original"

    if [ -f hadoop-config/yarn-site.xml.backup ]; then
        mv hadoop-config/yarn-site.xml.backup hadoop-config/yarn-site.xml
        docker-compose restart hadoop-master hadoop-worker1 hadoop-worker2
        sleep 40
        echo_info "Configuração restaurada!"
    fi
}

# Main
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
        echo "  baseline  - Teste com configuração padrão (2048MB)"
        echo "  test_low  - Teste com memória baixa (1024MB)"
        echo "  test_high - Teste com memória alta (4096MB)"
        echo "  restore   - Restaurar configuração original"
        echo "  all       - Executar todos os testes"
        exit 1
        ;;
esac

echo ""
echo_section "Resultados salvos em: $RESULTS_FILE"
