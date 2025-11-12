#!/bin/bash
# Script Principal para Testes de Tolerância a Falhas

TEST_SCENARIO=$1
RESULTS_DIR="fault-tolerance/results"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_title() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
}

# Criar diretório de resultados
mkdir -p "$RESULTS_DIR"

# Função para executar WordCount e retornar Application ID
run_wordcount() {
    local output_dir=$1
    local description=$2

    echo_info "Iniciando job: $description"

    # Limpar output anterior
    docker exec hadoop-master hdfs dfs -rm -r -f "$output_dir" 2>/dev/null

    # Executar WordCount em background e capturar output
    local temp_output=$(mktemp)
    docker exec hadoop-master bash -c "
        hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
            wordcount \
            /fault-tolerance/input \
            $output_dir
    " > "$temp_output" 2>&1 &

    local PID=$!

    # Aguardar para capturar Application ID
    sleep 10

    # Extrair Application ID do output
    local APP_ID=$(grep -oE 'application_[0-9]+_[0-9]+' "$temp_output" | head -1)

    if [ -z "$APP_ID" ]; then
        echo_error "Não foi possível obter Application ID"
        cat "$temp_output"
        rm "$temp_output"
        return 1
    fi

    echo_info "Application ID: $APP_ID"
    rm "$temp_output"

    # Retornar Application ID
    echo "$APP_ID"
    return 0
}

# Função para coletar métricas do cluster
collect_cluster_metrics() {
    local output_file=$1

    echo "=== Métricas do Cluster ===" >> "$output_file"
    echo "Timestamp: $(date)" >> "$output_file"
    echo "" >> "$output_file"

    echo "--- YARN Nodes ---" >> "$output_file"
    docker exec hadoop-master yarn node -list >> "$output_file" 2>&1
    echo "" >> "$output_file"

    echo "--- HDFS Status ---" >> "$output_file"
    docker exec hadoop-master hdfs dfsadmin -report | head -30 >> "$output_file" 2>&1
    echo "" >> "$output_file"

    echo "--- Running Containers ---" >> "$output_file"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" >> "$output_file" 2>&1
    echo "" >> "$output_file"
}

# ==================================================
# TESTE 1: BASELINE - Cluster completo sem falhas
# ==================================================
test_baseline() {
    echo_title "TESTE 1: BASELINE - Performance sem Falhas"

    local RESULT_FILE="$RESULTS_DIR/test1_baseline.txt"
    echo "TESTE 1: BASELINE - Performance sem Falhas" > "$RESULT_FILE"
    echo "Data: $(date)" >> "$RESULT_FILE"
    echo "========================================" >> "$RESULT_FILE"
    echo "" >> "$RESULT_FILE"

    echo_info "Verificando cluster (deve ter 2 workers ativos)..."
    collect_cluster_metrics "$RESULT_FILE"

    echo_info "Iniciando WordCount..."
    START_TIME=$(date +%s)

    APP_ID=$(run_wordcount "/fault-tolerance/output_baseline" "Baseline Test")

    if [ -z "$APP_ID" ]; then
        echo_error "Falha ao iniciar job"
        return 1
    fi

    # Monitorar job
    ./fault-tolerance/scripts/monitor_job.sh "$APP_ID" "$RESULTS_DIR/test1_monitor.log"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "" >> "$RESULT_FILE"
    echo "Tempo total de execução: ${DURATION}s ($((DURATION / 60))m $((DURATION % 60))s)" >> "$RESULT_FILE"

    # Coletar métricas finais
    collect_cluster_metrics "$RESULT_FILE"

    echo_info "Teste BASELINE concluído!"
    echo_info "Resultados em: $RESULT_FILE"
}

# ==================================================
# TESTE 2: Remoção de 1 Worker durante execução
# ==================================================
test_worker_failure() {
    echo_title "TESTE 2: Falha de 1 Worker Durante Execução"

    local RESULT_FILE="$RESULTS_DIR/test2_worker_failure.txt"
    echo "TESTE 2: Falha de 1 Worker Durante Execução" > "$RESULT_FILE"
    echo "Data: $(date)" >> "$RESULT_FILE"
    echo "========================================" >> "$RESULT_FILE"
    echo "" >> "$RESULT_FILE"

    echo_info "Estado inicial do cluster..."
    collect_cluster_metrics "$RESULT_FILE"

    echo_info "Iniciando WordCount..."
    START_TIME=$(date +%s)

    APP_ID=$(run_wordcount "/fault-tolerance/output_failure" "Worker Failure Test")

    if [ -z "$APP_ID" ]; then
        echo_error "Falha ao iniciar job"
        return 1
    fi

    # Aguardar job começar (30 segundos)
    echo_info "Aguardando job iniciar (30s)..."
    sleep 30

    # FALHA: Remover worker1
    echo_warn "🔥 INJETANDO FALHA: Removendo hadoop-worker1..."
    echo "" >> "$RESULT_FILE"
    echo "FALHA INJETADA: Remoção de hadoop-worker1 em $(date)" >> "$RESULT_FILE"
    docker-compose stop hadoop-worker1

    # Continuar monitorando
    ./fault-tolerance/scripts/monitor_job.sh "$APP_ID" "$RESULTS_DIR/test2_monitor.log"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "" >> "$RESULT_FILE"
    echo "Tempo total de execução: ${DURATION}s" >> "$RESULT_FILE"

    # Métricas finais (com 1 worker a menos)
    collect_cluster_metrics "$RESULT_FILE"

    # Restaurar worker1
    echo_info "Restaurando hadoop-worker1..."
    docker-compose start hadoop-worker1
    sleep 20

    echo_info "Teste de FALHA concluído!"
    echo_info "Resultados em: $RESULT_FILE"
}

# ==================================================
# TESTE 3: Adição de Worker durante execução (Scale Up)
# ==================================================
test_scale_up() {
    echo_title "TESTE 3: Adição de Worker Durante Execução (Scale Up)"

    local RESULT_FILE="$RESULTS_DIR/test3_scale_up.txt"
    echo "TESTE 3: Scale Up - Adicionar Worker Durante Execução" > "$RESULT_FILE"
    echo "Data: $(date)" >> "$RESULT_FILE"
    echo "========================================" >> "$RESULT_FILE"
    echo "" >> "$RESULT_FILE"

    # Iniciar com apenas 1 worker
    echo_info "Parando worker2 para iniciar com apenas 1 worker..."
    docker-compose stop hadoop-worker2
    sleep 20

    collect_cluster_metrics "$RESULT_FILE"

    echo_info "Iniciando WordCount com 1 worker..."
    START_TIME=$(date +%s)

    APP_ID=$(run_wordcount "/fault-tolerance/output_scaleup" "Scale Up Test")

    if [ -z "$APP_ID" ]; then
        echo_error "Falha ao iniciar job"
        return 1
    fi

    # Aguardar job começar
    echo_info "Aguardando job iniciar (30s)..."
    sleep 30

    # SCALE UP: Adicionar worker2
    echo_info "📈 SCALE UP: Adicionando hadoop-worker2..."
    echo "" >> "$RESULT_FILE"
    echo "SCALE UP: Adição de hadoop-worker2 em $(date)" >> "$RESULT_FILE"
    docker-compose start hadoop-worker2
    sleep 20

    # Continuar monitorando
    ./fault-tolerance/scripts/monitor_job.sh "$APP_ID" "$RESULTS_DIR/test3_monitor.log"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "" >> "$RESULT_FILE"
    echo "Tempo total de execução: ${DURATION}s" >> "$RESULT_FILE"

    collect_cluster_metrics "$RESULT_FILE"

    echo_info "Teste SCALE UP concluído!"
    echo_info "Resultados em: $RESULT_FILE"
}

# ==================================================
# TESTE 4: Falhas Múltiplas (remover ambos workers)
# ==================================================
test_multiple_failures() {
    echo_title "TESTE 4: Falhas Múltiplas (2 Workers)"

    local RESULT_FILE="$RESULTS_DIR/test4_multiple_failures.txt"
    echo "TESTE 4: Falhas Múltiplas - Remoção de 2 Workers" > "$RESULT_FILE"
    echo "Data: $(date)" >> "$RESULT_FILE"
    echo "========================================" >> "$RESULT_FILE"
    echo "" >> "$RESULT_FILE"

    collect_cluster_metrics "$RESULT_FILE"

    echo_info "Iniciando WordCount..."
    START_TIME=$(date +%s)

    APP_ID=$(run_wordcount "/fault-tolerance/output_multi" "Multiple Failures Test")

    if [ -z "$APP_ID" ]; then
        echo_error "Falha ao iniciar job"
        return 1
    fi

    sleep 20

    # FALHA 1: Remover worker1
    echo_warn "🔥 FALHA 1: Removendo hadoop-worker1..."
    echo "FALHA 1: Remoção de hadoop-worker1 em $(date)" >> "$RESULT_FILE"
    docker-compose stop hadoop-worker1
    sleep 20

    # FALHA 2: Remover worker2
    echo_warn "🔥 FALHA 2: Removendo hadoop-worker2..."
    echo "FALHA 2: Remoção de hadoop-worker2 em $(date)" >> "$RESULT_FILE"
    docker-compose stop hadoop-worker2

    # Monitorar (job deve falhar)
    ./fault-tolerance/scripts/monitor_job.sh "$APP_ID" "$RESULTS_DIR/test4_monitor.log"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "" >> "$RESULT_FILE"
    echo "Tempo até falha: ${DURATION}s" >> "$RESULT_FILE"

    collect_cluster_metrics "$RESULT_FILE"

    # Restaurar workers
    echo_info "Restaurando workers..."
    docker-compose start hadoop-worker1 hadoop-worker2
    sleep 30

    echo_info "Teste de FALHAS MÚLTIPLAS concluído!"
    echo_info "Resultados em: $RESULT_FILE"
}

# ==================================================
# MAIN
# ==================================================

case "$TEST_SCENARIO" in
    baseline|1)
        test_baseline
        ;;
    worker-failure|2)
        test_worker_failure
        ;;
    scale-up|3)
        test_scale_up
        ;;
    multiple-failures|4)
        test_multiple_failures
        ;;
    all)
        test_baseline
        echo_info "Aguardando 30s antes do próximo teste..."
        sleep 30
        test_worker_failure
        sleep 30
        test_scale_up
        sleep 30
        test_multiple_failures
        ;;
    *)
        echo "Uso: $0 {baseline|worker-failure|scale-up|multiple-failures|all}"
        echo ""
        echo "Testes disponíveis:"
        echo "  baseline (1)           - Medição de performance sem falhas"
        echo "  worker-failure (2)     - Remover 1 worker durante execução"
        echo "  scale-up (3)           - Adicionar 1 worker durante execução"
        echo "  multiple-failures (4)  - Remover ambos workers"
        echo "  all                    - Executar todos os testes"
        exit 1
        ;;
esac

echo ""
echo_title "Teste Concluído!"
echo "Resultados salvos em: $RESULTS_DIR/"
