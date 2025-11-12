#!/bin/bash
# Teste 3: Impacto de Múltiplas Filas no Capacity Scheduler

RESULTS_FILE="tests/results/test3_results.txt"

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

# Coletar métricas do scheduler
collect_scheduler_metrics() {
    local test_name=$1
    echo_section "Coletando Métricas do Scheduler - $test_name"

    echo "=== $test_name ===" >> $RESULTS_FILE
    echo "Timestamp: $(date)" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Configuração do scheduler
    echo "Configuração do Capacity Scheduler:" >> $RESULTS_FILE
    docker exec hadoop-master cat /opt/hadoop/etc/hadoop/capacity-scheduler.xml 2>/dev/null >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Aplicações por fila
    echo "Aplicações por Fila:" >> $RESULTS_FILE
    docker exec hadoop-master yarn application -list 2>/dev/null >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Status das filas via REST API
    echo "Status das Filas (REST API):" >> $RESULTS_FILE
    docker exec hadoop-master curl -s http://localhost:8088/ws/v1/cluster/scheduler 2>/dev/null | python3 -m json.tool >> $RESULTS_FILE 2>/dev/null || echo "API não disponível" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    echo "----------------------------------------" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
}

# Configuração com 1 fila (baseline)
apply_single_queue() {
    echo_info "Aplicando configuração de fila única (default)"

    cat > hadoop-config/capacity-scheduler.xml <<'EOF'
<?xml version="1.0"?>
<configuration>
  <property>
    <name>yarn.scheduler.capacity.root.queues</name>
    <value>default</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.default.capacity</name>
    <value>100</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.default.maximum-capacity</name>
    <value>100</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.default.state</name>
    <value>RUNNING</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.default.acl_submit_applications</name>
    <value>*</value>
  </property>
</configuration>
EOF

    # Restart
    docker-compose restart hadoop-master
    sleep 40
}

# Configuração com 3 filas (high, default, low)
apply_multi_queue() {
    echo_info "Aplicando configuração de múltiplas filas (high, default, low)"

    cat > hadoop-config/capacity-scheduler.xml <<'EOF'
<?xml version="1.0"?>
<configuration>
  <!-- Definir 3 filas: high (50%), default (30%), low (20%) -->
  <property>
    <name>yarn.scheduler.capacity.root.queues</name>
    <value>high,default,low</value>
    <description>Três filas com prioridades diferentes</description>
  </property>

  <!-- Fila HIGH - Alta prioridade, 50% dos recursos -->
  <property>
    <name>yarn.scheduler.capacity.root.high.capacity</name>
    <value>50</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.high.maximum-capacity</name>
    <value>80</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.high.state</name>
    <value>RUNNING</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.high.acl_submit_applications</name>
    <value>*</value>
  </property>

  <!-- Fila DEFAULT - Prioridade normal, 30% dos recursos -->
  <property>
    <name>yarn.scheduler.capacity.root.default.capacity</name>
    <value>30</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.default.maximum-capacity</name>
    <value>50</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.default.state</name>
    <value>RUNNING</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.default.acl_submit_applications</name>
    <value>*</value>
  </property>

  <!-- Fila LOW - Baixa prioridade, 20% dos recursos -->
  <property>
    <name>yarn.scheduler.capacity.root.low.capacity</name>
    <value>20</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.low.maximum-capacity</name>
    <value>30</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.low.state</name>
    <value>RUNNING</value>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.low.acl_submit_applications</name>
    <value>*</value>
  </property>

  <!-- Configurações globais -->
  <property>
    <name>yarn.scheduler.capacity.maximum-am-resource-percent</name>
    <value>0.5</value>
  </property>
</configuration>
EOF

    # Restart
    docker-compose restart hadoop-master
    sleep 40
}

# Teste baseline
test_baseline() {
    echo_section "TESTE BASELINE - Fila Única"

    echo "TESTE 3: Impacto de Múltiplas Filas no Capacity Scheduler" > $RESULTS_FILE
    echo "Data: $(date)" >> $RESULTS_FILE
    echo "========================================" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    apply_single_queue
    collect_scheduler_metrics "BASELINE (Single Queue)"

    echo_info "Baseline concluído!"
}

# Teste com múltiplas filas
test_multi_queue() {
    echo_section "TESTE MULTI-QUEUE - 3 Filas com Prioridades"

    apply_multi_queue
    collect_scheduler_metrics "TEST_MULTI (3 Queues: high/default/low)"

    echo_info "Teste MULTI-QUEUE concluído!"
}

# Teste de priorização
test_priority() {
    echo_section "TESTE DE PRIORIZAÇÃO - Submeter Jobs em Diferentes Filas"

    # Preparar dados
    docker exec hadoop-master bash -c "
        echo 'Priority test data' > /tmp/priority_test.txt
        for i in {1..500}; do
            echo 'Line \$i: Testing queue priority and resource allocation' >> /tmp/priority_test.txt
        done
        hdfs dfs -rm -r -f /test_priority
        hdfs dfs -mkdir -p /test_priority/input
        hdfs dfs -put -f /tmp/priority_test.txt /test_priority/input/
    " 2>/dev/null

    echo_info "Submetendo job na fila LOW..."
    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_priority/output_low
        hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
            wordcount \
            -Dmapreduce.job.queuename=low \
            /test_priority/input /test_priority/output_low &
    " >> $RESULTS_FILE 2>&1 &

    sleep 2

    echo_info "Submetendo job na fila DEFAULT..."
    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_priority/output_default
        hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
            wordcount \
            -Dmapreduce.job.queuename=default \
            /test_priority/input /test_priority/output_default &
    " >> $RESULTS_FILE 2>&1 &

    sleep 2

    echo_info "Submetendo job na fila HIGH..."
    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_priority/output_high
        hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
            wordcount \
            -Dmapreduce.job.queuename=high \
            /test_priority/input /test_priority/output_high &
    " >> $RESULTS_FILE 2>&1 &

    echo_info "Aguardando execução dos jobs..."
    sleep 60

    # Coletar resultados
    echo "" >> $RESULTS_FILE
    echo "Jobs Submetidos em Diferentes Filas:" >> $RESULTS_FILE
    docker exec hadoop-master yarn application -list -appStates ALL >> $RESULTS_FILE 2>&1

    echo_info "Teste de PRIORIZAÇÃO concluído!"
}

# Restaurar configuração
restore_config() {
    echo_section "Restaurando Configuração Original"
    apply_single_queue
    echo_info "Configuração restaurada!"
}

# Main
case "$1" in
    baseline)
        test_baseline
        ;;
    test_multi_queue)
        test_multi_queue
        ;;
    test_priority)
        test_priority
        ;;
    restore)
        restore_config
        ;;
    all)
        test_baseline
        test_multi_queue
        test_priority
        restore_config
        ;;
    *)
        echo "Uso: $0 {baseline|test_multi_queue|test_priority|restore|all}"
        echo ""
        echo "  baseline         - Teste com fila única"
        echo "  test_multi_queue - Criar 3 filas com diferentes capacidades"
        echo "  test_priority    - Testar priorização de jobs"
        echo "  restore          - Restaurar configuração original"
        echo "  all              - Executar todos os testes"
        exit 1
        ;;
esac

echo ""
echo_section "Resultados salvos em: $RESULTS_FILE"
