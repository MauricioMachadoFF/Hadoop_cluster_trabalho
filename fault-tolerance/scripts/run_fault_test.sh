#!/bin/bash
# Fault Tolerance Test Runner

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_title() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

TEST_TYPE=${1:-baseline}
RESULTS_DIR="fault-tolerance/results"
HDFS_INPUT="/fault-tolerance/input"
HDFS_OUTPUT="/fault-tolerance/output"

mkdir -p $RESULTS_DIR

echo_title "Teste de Tolerância a Falhas - $TEST_TYPE"

# Function to run WordCount job
run_wordcount_job() {
    local job_name=$1
    local output_dir=$2
    
    echo_info "Limpando output anterior..."
    docker exec hadoop-master hdfs dfs -rm -r -f $output_dir 2>/dev/null || true
    
    echo_info "Iniciando job MapReduce: $job_name"
    echo_info "Input: $HDFS_INPUT"
    echo_info "Output: $output_dir"
    
    START_TIME=$(date +%s)
    
    docker exec hadoop-master bash -c "
        hadoop jar \$HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \
            -input $HDFS_INPUT \
            -output $output_dir \
            -mapper 'cat' \
            -reducer 'wc -w' \
            -numReduceTasks 2
    " 2>&1
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    echo_info "Job concluído em ${DURATION}s"
    
    return 0
}

# Function to check cluster health
check_cluster_health() {
    echo_info "Verificando saúde do cluster..."
    
    echo "DataNodes ativos:"
    docker exec hadoop-master hdfs dfsadmin -report 2>/dev/null | grep -A 2 "Live datanodes"
    
    echo ""
    echo "NodeManagers ativos:"
    docker exec hadoop-master yarn node -list 2>/dev/null | grep RUNNING
    
    echo ""
}

# Baseline Test - No failures
if [ "$TEST_TYPE" == "baseline" ]; then
    RESULT_FILE="$RESULTS_DIR/test1_baseline.txt"
    
    echo_info "TESTE BASELINE - Sem falhas" | tee $RESULT_FILE
    echo "=====================================" | tee -a $RESULT_FILE
    echo "" | tee -a $RESULT_FILE
    
    check_cluster_health | tee -a $RESULT_FILE
    
    echo_info "Executando job MapReduce..." | tee -a $RESULT_FILE
    run_wordcount_job "Baseline WordCount" "${HDFS_OUTPUT}_baseline" 2>&1 | tee -a $RESULT_FILE
    
    echo "" | tee -a $RESULT_FILE
    echo_info "Verificando resultados..." | tee -a $RESULT_FILE
    docker exec hadoop-master hdfs dfs -ls -h ${HDFS_OUTPUT}_baseline 2>&1 | tee -a $RESULT_FILE
    docker exec hadoop-master hdfs dfs -cat ${HDFS_OUTPUT}_baseline/part-* 2>&1 | tee -a $RESULT_FILE
    
    echo "" | tee -a $RESULT_FILE
    check_cluster_health | tee -a $RESULT_FILE
    
    echo_title "Teste Baseline Concluído!"
    echo_info "Resultados salvos em: $RESULT_FILE"
fi

# Worker Failure Test
if [ "$TEST_TYPE" == "worker-failure" ]; then
    RESULT_FILE="$RESULTS_DIR/test2_worker_failure.txt"
    
    echo_info "TESTE DE FALHA DE WORKER" | tee $RESULT_FILE
    echo "=====================================" | tee -a $RESULT_FILE
    echo "" | tee -a $RESULT_FILE
    
    check_cluster_health | tee -a $RESULT_FILE
    
    echo_info "Iniciando job MapReduce..." | tee -a $RESULT_FILE
    
    # Start job in background
    (run_wordcount_job "Worker Failure Test" "${HDFS_OUTPUT}_failure" 2>&1 | tee -a $RESULT_FILE) &
    JOB_PID=$!
    
    echo_info "Aguardando 15 segundos para job iniciar..." | tee -a $RESULT_FILE
    sleep 15
    
    echo_warning "SIMULANDO FALHA: Removendo hadoop-worker2..." | tee -a $RESULT_FILE
    docker stop hadoop-worker2 2>&1 | tee -a $RESULT_FILE
    
    echo_info "Worker2 removido! Aguardando job completar..." | tee -a $RESULT_FILE
    wait $JOB_PID
    JOB_EXIT_CODE=$?
    
    echo "" | tee -a $RESULT_FILE
    if [ $JOB_EXIT_CODE -eq 0 ]; then
        echo_info "Job completou com sucesso mesmo com falha!" | tee -a $RESULT_FILE
    else
        echo_error "Job falhou (exit code: $JOB_EXIT_CODE)" | tee -a $RESULT_FILE
    fi
    
    echo "" | tee -a $RESULT_FILE
    echo_info "Verificando resultados..." | tee -a $RESULT_FILE
    docker exec hadoop-master hdfs dfs -ls -h ${HDFS_OUTPUT}_failure 2>&1 | tee -a $RESULT_FILE
    docker exec hadoop-master hdfs dfs -cat ${HDFS_OUTPUT}_failure/part-* 2>&1 | tee -a $RESULT_FILE
    
    echo "" | tee -a $RESULT_FILE
    check_cluster_health | tee -a $RESULT_FILE
    
    echo_warning "Restaurando worker2..." | tee -a $RESULT_FILE
    docker start hadoop-worker2 2>&1 | tee -a $RESULT_FILE
    sleep 10
    
    echo "" | tee -a $RESULT_FILE
    check_cluster_health | tee -a $RESULT_FILE
    
    echo_title "Teste de Falha de Worker Concluído!"
    echo_info "Resultados salvos em: $RESULT_FILE"
fi

# All tests
if [ "$TEST_TYPE" == "all" ]; then
    echo_info "Executando todos os testes..."
    
    $0 baseline
    echo ""
    echo "Aguardando 10 segundos entre testes..."
    sleep 10
    echo ""
    
    $0 worker-failure
    
    echo_title "Todos os Testes Concluídos!"
fi

# Usage
if [ "$TEST_TYPE" != "baseline" ] && [ "$TEST_TYPE" != "worker-failure" ] && [ "$TEST_TYPE" != "all" ]; then
    echo_error "Tipo de teste inválido: $TEST_TYPE"
    echo ""
    echo "Uso: $0 [test-type]"
    echo ""
    echo "Tipos de teste disponíveis:"
    echo "  baseline        - Teste sem falhas (baseline)"
    echo "  worker-failure  - Teste com falha de worker durante execução"
    echo "  all            - Executar todos os testes"
    echo ""
    exit 1
fi
