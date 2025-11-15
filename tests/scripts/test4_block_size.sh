#!/bin/bash
# Teste 4: Impacto do Tamanho de Blocos HDFS

RESULTS_FILE="tests/results/test4_results.txt"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Função para verificar safe mode
wait_safe_mode() {
    echo_info "Verificando se HDFS está pronto..."
    local max_attempts=30
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if docker exec hadoop-master hdfs dfsadmin -safemode get 2>/dev/null | grep -q "OFF"; then
            echo_info "HDFS está pronto!"
            return 0
        fi
        echo_info "Aguardando HDFS sair do safe mode... tentativa $((attempt+1))/$max_attempts"
        sleep 3
        attempt=$((attempt+1))
    done
    echo_info "Timeout aguardando safe mode"
    return 1
}

collect_block_metrics() {
    local test_name=$1
    echo_section "Coletando Métricas de Blocos - $test_name"

    echo "=== $test_name ===" >> $RESULTS_FILE
    echo "Timestamp: $(date)" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Informações dos arquivos
    echo "Informações dos Arquivos:" >> $RESULTS_FILE
    docker exec hadoop-master hdfs dfs -ls /test_blocksize/ >> $RESULTS_FILE 2>&1
    echo "" >> $RESULTS_FILE

    # FSCK com detalhes de blocos
    echo "Análise de Blocos (FSCK):" >> $RESULTS_FILE
    docker exec hadoop-master hdfs fsck /test_blocksize/ -files -blocks -locations >> $RESULTS_FILE 2>&1
    echo "" >> $RESULTS_FILE

    # Estatísticas
    echo "Estatísticas:" >> $RESULTS_FILE
    docker exec hadoop-master hdfs dfs -count /test_blocksize/ >> $RESULTS_FILE 2>&1
    echo "" >> $RESULTS_FILE

    echo "----------------------------------------" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE
}

apply_block_size() {
    local block_size=$1
    echo_info "Aplicando block size: ${block_size}"

    # Backup
    cp hadoop-config/hdfs-site.xml hadoop-config/hdfs-site.xml.backup

    # Adicionar configuração de block size
    cat > tests/configurations/test4/hdfs-site-${block_size}.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
    <property>
        <name>dfs.blocksize</name>
        <value>$block_size</value>
        <description>TESTE: Tamanho dos blocos HDFS</description>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:///hadoop/dfs/name</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:///hadoop/dfs/data</value>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>0.0.0.0:9870</value>
    </property>
    <property>
        <name>dfs.permissions.enabled</name>
        <value>false</value>
    </property>
</configuration>
EOF

    cp tests/configurations/test4/hdfs-site-${block_size}.xml hadoop-config/hdfs-site.xml

    # Restart
    docker-compose restart hadoop-master hadoop-worker1 hadoop-worker2
    sleep 35

    # Aguardar HDFS sair do safe mode
    wait_safe_mode
}

create_test_file() {
    local size_mb=$1
    local filename=$2
    echo_info "Criando arquivo de teste: ${filename} (${size_mb}MB)"

    docker exec hadoop-master bash -c "
        dd if=/dev/urandom of=/tmp/${filename} bs=1M count=${size_mb} 2>/dev/null
    "
}

test_baseline() {
    echo_section "TESTE BASELINE - Block Size = 128MB"

    echo "TESTE 4: Impacto do Tamanho de Blocos HDFS" > $RESULTS_FILE
    echo "Data: $(date)" >> $RESULTS_FILE
    echo "========================================" >> $RESULTS_FILE
    echo "" >> $RESULTS_FILE

    # Verificar se HDFS está pronto
    wait_safe_mode

    # Criar arquivo de 200MB
    create_test_file 200 "blocktest_128mb.dat"

    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_blocksize
        hdfs dfs -mkdir -p /test_blocksize
        hdfs dfs -put /tmp/blocktest_128mb.dat /test_blocksize/
    "

    collect_block_metrics "BASELINE (BlockSize=128MB)"

    echo_info "Baseline concluído!"
}

test_small() {
    echo_section "TESTE SMALL - Block Size = 64MB"

    apply_block_size "67108864"  # 64MB em bytes

    # Verificar safe mode antes das operações HDFS
    wait_safe_mode

    create_test_file 200 "blocktest_64mb.dat"

    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_blocksize
        hdfs dfs -mkdir -p /test_blocksize
        hdfs dfs -put /tmp/blocktest_64mb.dat /test_blocksize/
    "

    collect_block_metrics "TEST_SMALL (BlockSize=64MB)"

    echo_info "Teste SMALL concluído!"
}

test_large() {
    echo_section "TESTE LARGE - Block Size = 256MB"

    apply_block_size "268435456"  # 256MB em bytes

    # Verificar safe mode antes das operações HDFS
    wait_safe_mode

    create_test_file 512 "blocktest_256mb.dat"

    docker exec hadoop-master bash -c "
        hdfs dfs -rm -r -f /test_blocksize
        hdfs dfs -mkdir -p /test_blocksize
        hdfs dfs -put /tmp/blocktest_256mb.dat /test_blocksize/
    "

    collect_block_metrics "TEST_LARGE (BlockSize=256MB)"

    echo_info "Teste LARGE concluído!"
}

restore_config() {
    echo_section "Restaurando Configuração Original"

    if [ -f hadoop-config/hdfs-site.xml.backup ]; then
        mv hadoop-config/hdfs-site.xml.backup hadoop-config/hdfs-site.xml
        docker-compose restart hadoop-master hadoop-worker1 hadoop-worker2
        sleep 35

        # Aguardar HDFS sair do safe mode
        wait_safe_mode

        echo_info "Configuração restaurada!"
    fi
}

case "$1" in
    baseline)
        test_baseline
        ;;
    test_small)
        test_small
        ;;
    test_large)
        test_large
        ;;
    restore)
        restore_config
        ;;
    all)
        test_baseline
        test_small
        test_large
        restore_config
        ;;
    *)
        echo "Uso: $0 {baseline|test_small|test_large|restore|all}"
        echo ""
        echo "  baseline   - Teste com block size padrão (128MB)"
        echo "  test_small - Teste com blocks pequenos (64MB)"
        echo "  test_large - Teste com blocks grandes (256MB)"
        echo "  restore    - Restaurar configuração original"
        echo "  all        - Executar todos os testes"
        exit 1
        ;;
esac

echo ""
echo_section "Resultados salvos em: $RESULTS_FILE"
