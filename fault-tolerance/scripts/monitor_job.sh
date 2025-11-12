#!/bin/bash
# Monitor de Jobs Hadoop em Tempo Real

APPLICATION_ID=$1
OUTPUT_FILE=${2:-"fault-tolerance/monitoring/job_monitor.log"}
INTERVAL=5  # segundos entre atualizações

if [ -z "$APPLICATION_ID" ]; then
    echo "Uso: $0 <application_id> [output_file]"
    echo "Exemplo: $0 application_1234567890_0001"
    exit 1
fi

mkdir -p $(dirname "$OUTPUT_FILE")

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$OUTPUT_FILE"
}

echo_warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$OUTPUT_FILE"
}

echo_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$OUTPUT_FILE"
}

echo_title() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n" | tee -a "$OUTPUT_FILE"
}

# Inicializar log
echo_title "Monitor de Job Hadoop - $APPLICATION_ID"
echo "Início do monitoramento: $(date)" >> "$OUTPUT_FILE"
echo "----------------------------------------" >> "$OUTPUT_FILE"

START_TIME=$(date +%s)
PREVIOUS_PROGRESS=0

while true; do
    # Coletar status da aplicação
    APP_STATUS=$(docker exec hadoop-master yarn application -status "$APPLICATION_ID" 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo_error "Falha ao obter status da aplicação"
        sleep $INTERVAL
        continue
    fi

    # Extrair informações
    STATE=$(echo "$APP_STATUS" | grep "State :" | awk '{print $3}')
    FINAL_STATUS=$(echo "$APP_STATUS" | grep "Final-State :" | awk '{print $3}')
    PROGRESS=$(echo "$APP_STATUS" | grep "Progress :" | awk '{print $3}' | tr -d '%')

    # Status dos NodeManagers
    NODES_STATUS=$(docker exec hadoop-master yarn node -list 2>/dev/null | grep "Total Nodes" || echo "Nodes: Unknown")

    # Tempo decorrido
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    ELAPSED_MIN=$((ELAPSED / 60))
    ELAPSED_SEC=$((ELAPSED % 60))

    # Limpar tela e mostrar status
    clear
    echo_title "Monitor de Job Hadoop"

    echo -e "${BLUE}Application ID:${NC} $APPLICATION_ID"
    echo -e "${BLUE}Estado:${NC} $STATE"
    if [ "$PROGRESS" != "" ]; then
        echo -e "${BLUE}Progresso:${NC} ${PROGRESS}%"
    fi
    echo -e "${BLUE}Tempo decorrido:${NC} ${ELAPSED_MIN}m ${ELAPSED_SEC}s"
    echo ""

    # Status do cluster
    echo -e "${BLUE}Status do Cluster:${NC}"
    echo "$NODES_STATUS"
    echo ""

    # Registrar no log se houve mudança significativa
    if [ "$PROGRESS" != "" ] && [ "$PROGRESS" != "$PREVIOUS_PROGRESS" ]; then
        echo "[$(date '+%H:%M:%S')] Progress: ${PROGRESS}% | State: $STATE | Elapsed: ${ELAPSED}s | $NODES_STATUS" >> "$OUTPUT_FILE"
        PREVIOUS_PROGRESS=$PROGRESS
    fi

    # Verificar se terminou
    if [ "$STATE" == "FINISHED" ] || [ "$STATE" == "FAILED" ] || [ "$STATE" == "KILLED" ]; then
        echo ""
        if [ "$STATE" == "FINISHED" ]; then
            echo_info "✓ Job concluído com sucesso!"
        elif [ "$STATE" == "FAILED" ]; then
            echo_error "✗ Job falhou!"
        else
            echo_warn "⚠ Job foi cancelado!"
        fi

        echo ""
        echo "Final Status: $FINAL_STATUS"
        echo "Tempo total: ${ELAPSED_MIN}m ${ELAPSED_SEC}s"

        # Estatísticas finais
        echo "" | tee -a "$OUTPUT_FILE"
        echo "========================================" | tee -a "$OUTPUT_FILE"
        echo "RESUMO FINAL" | tee -a "$OUTPUT_FILE"
        echo "========================================" | tee -a "$OUTPUT_FILE"
        echo "Application ID: $APPLICATION_ID" | tee -a "$OUTPUT_FILE"
        echo "Estado Final: $STATE ($FINAL_STATUS)" | tee -a "$OUTPUT_FILE"
        echo "Tempo Total: ${ELAPSED_MIN}m ${ELAPSED_SEC}s" | tee -a "$OUTPUT_FILE"
        echo "Término: $(date)" | tee -a "$OUTPUT_FILE"
        echo "" | tee -a "$OUTPUT_FILE"

        # Logs da aplicação
        echo "Coletando logs da aplicação..." | tee -a "$OUTPUT_FILE"
        docker exec hadoop-master yarn logs -applicationId "$APPLICATION_ID" >> "$OUTPUT_FILE" 2>&1

        break
    fi

    sleep $INTERVAL
done

echo ""
echo_info "Log salvo em: $OUTPUT_FILE"
