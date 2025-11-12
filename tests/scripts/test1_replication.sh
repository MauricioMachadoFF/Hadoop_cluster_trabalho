#!/bin/bash
# Teste 1: Impacto do Fator de Replicação HDFS

RESULTS_FILE="tests/results/test1_results.txt"
TEST_FILE="/tmp/test_replication.txt"

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Função para coletar métricas HDFS
collect_hdfs_metrics() {
    local test_name=$1
    echo_section "Coletando Métricas HDFS - $test_name"

    echo "=== $test_name ===" >> $RESULTS_FILE
    echo "Timestamp: $(date)" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # HDFS Report
    echo "HDFS Status:" >> $RESULTS_FILE
    docker exec hadoop-master hdfs dfsadmin -report 2>/dev/null | head -30 >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Listar arquivos de teste
    echo "Arquivos de Teste:" >> $RESULTS_FILE
    docker exec hadoop-master hdfs dfs -ls -R /test_replication 2>/dev/null >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Status dos blocos
    echo "Status dos Blocos:" >> $RESULTS_FILE
    docker exec hadoop-master hdfs fsck /test_replication -files -blocks -locations 2>/dev/null >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
    echo "----------------------------------------" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
}

# Função para criar arquivo de teste
create_test_file() {
    local size_mb=$1
    echo_info "Criando arquivo de teste de ${size_mb}MB..."

    # Criar arquivo localmente
    dd if=/dev/zero of=$TEST_FILE bs=1M count=$size_mb 2>/dev/null

    # Copiar para container
    docker cp $TEST_FILE hadoop-master:/tmp/
}

# Função para aplicar configuração
apply_replication() {
    local rep_factor=$1
    echo_info "Aplicando fator de replicação: $rep_factor"

    # Backup da configuração atual
    cp hadoop-config/hdfs-site.xml hadoop-config/hdfs-site.xml.backup

    # Atualizar configuração
    sed -i.bak "s/<value>.*<\/value>/<value>$rep_factor<\/value>/" hadoop-config/hdfs-site.xml

    # Restart cluster
    echo_info "Reiniciando cluster..."
    docker-compose restart hadoop-master hadoop-worker1 hadoop-worker2
    sleep 30
}

# Teste baseline
test_baseline() {
    echo_section "TESTE BASELINE - Replicação = 2"

    # Inicializar arquivo de resultados
    echo "TESTE 1: Impacto do Fator de Replicação HDFS" > $RESULTS_FILE
    echo "Data: $(date)" >> $RESULTS_FILE
    echo "========================================" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Criar arquivo de teste
    create_test_file 100

    # Upload para HDFS
    echo_info "Fazendo upload para HDFS..."
    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_replication
        hdfs dfs -mkdir -p /test_replication
        hdfs dfs -put /tmp/test_replication.txt /test_replication/
    "

    # Coletar métricas
    collect_hdfs_metrics "BASELINE (Replication=2)"

    echo_info "Baseline concluído!"
}

# Teste com replicação = 1
test_rep1() {
    echo_section "TESTE REP=1 - Menor Uso de Disco"

    # Aplicar configuração
    apply_replication 1

    # Criar novo arquivo
    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_replication
        hdfs dfs -mkdir -p /test_replication
        hdfs dfs -setrep -w 1 /test_replication
        hdfs dfs -put /tmp/test_replication.txt /test_replication/
    "

    # Aguardar replicação
    sleep 10

    # Coletar métricas
    collect_hdfs_metrics "TEST_REP1 (Replication=1)"

    echo_info "Teste REP=1 concluído!"
}

# Teste com replicação = 3
test_rep3() {
    echo_section "TESTE REP=3 - Maior Disponibilidade"

    # Aplicar configuração
    apply_replication 3

    # Criar novo arquivo
    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_replication
        hdfs dfs -mkdir -p /test_replication
        hdfs dfs -setrep -w 3 /test_replication
        hdfs dfs -put /tmp/test_replication.txt /test_replication/
    "

    # Aguardar replicação (pode levar mais tempo)
    sleep 15

    # Coletar métricas
    collect_hdfs_metrics "TEST_REP3 (Replication=3)"

    echo_info "Teste REP=3 concluído!"
}

# Restaurar configuração original
restore_config() {
    echo_section "Restaurando Configuração Original"

    if [ -f hadoop-config/hdfs-site.xml.backup ]; then
        mv hadoop-config/hdfs-site.xml.backup hadoop-config/hdfs-site.xml
        docker-compose restart hadoop-master hadoop-worker1 hadoop-worker2
        sleep 30
        echo_info "Configuração restaurada!"
    fi
}

# Main
case "$1" in
    baseline)
        test_baseline
        ;;
    test_rep1)
        test_rep1
        ;;
    test_rep3)
        test_rep3
        ;;
    restore)
        restore_config
        ;;
    all)
        test_baseline
        test_rep1
        test_rep3
        restore_config
        ;;
    *)
        echo "Uso: $0 {baseline|test_rep1|test_rep3|restore|all}"
        echo ""
        echo "  baseline  - Teste com configuração padrão (rep=2)"
        echo "  test_rep1 - Teste com replicação = 1"
        echo "  test_rep3 - Teste com replicação = 3"
        echo "  restore   - Restaurar configuração original"
        echo "  all       - Executar todos os testes"
        exit 1
        ;;
esac

echo ""
echo_section "Resultados salvos em: $RESULTS_FILE"
