#!/bin/bash
# Upload test data to HDFS for fault tolerance testing

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

DATA_DIR="fault-tolerance/data"
HDFS_DIR="/fault-tolerance/input"

echo_title "Upload de Dados para HDFS"

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
    echo_error "Diretório $DATA_DIR não encontrado!"
    echo_error "Execute primeiro: ./fault-tolerance/scripts/generate_data.sh"
    exit 1
fi

# Check if there are files to upload
file_count=$(ls -1 $DATA_DIR/*.txt 2>/dev/null | wc -l)
if [ $file_count -eq 0 ]; then
    echo_error "Nenhum arquivo encontrado em $DATA_DIR"
    exit 1
fi

echo_info "Arquivos encontrados: $file_count"
ls -lh $DATA_DIR/

echo ""
echo_info "Aguardando HDFS sair do safe mode..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if docker exec hadoop-master hdfs dfsadmin -safemode get 2>/dev/null | grep -q "OFF"; then
        echo_info "HDFS está pronto!"
        break
    fi
    echo_info "Aguardando... tentativa $((attempt+1))/$max_attempts"
    sleep 2
    attempt=$((attempt+1))
done

if [ $attempt -eq $max_attempts ]; then
    echo_error "Timeout aguardando HDFS"
    exit 1
fi

echo ""
echo_info "Limpando diretório HDFS anterior (se existir)..."
docker exec hadoop-master hdfs dfs -rm -r -f $HDFS_DIR 2>/dev/null || true

echo_info "Criando diretório no HDFS: $HDFS_DIR"
docker exec hadoop-master hdfs dfs -mkdir -p $HDFS_DIR

echo ""
echo_info "Copiando arquivos locais para o container master..."
docker cp $DATA_DIR/. hadoop-master:/tmp/fault-tolerance-data/

echo_info "Fazendo upload para HDFS..."
docker exec hadoop-master bash -c "hdfs dfs -put /tmp/fault-tolerance-data/*.txt $HDFS_DIR/"

echo ""
echo_info "Verificando upload..."
docker exec hadoop-master hdfs dfs -ls -h $HDFS_DIR/

echo ""
echo_info "Verificando replicação e distribuição..."
docker exec hadoop-master hdfs fsck $HDFS_DIR/ -files -blocks -locations

echo ""
echo_title "Upload Concluído com Sucesso!"
echo_info "Dados disponíveis em: $HDFS_DIR"
echo_info "Próximo passo: ./fault-tolerance/scripts/run_fault_test.sh [test-type]"
