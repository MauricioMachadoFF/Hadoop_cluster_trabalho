#!/bin/bash
# Upload de dados para HDFS

DATA_DIR="fault-tolerance/data"
HDFS_DIR="/fault-tolerance/input"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_title() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

echo_title "Upload de Dados para HDFS"

# Verificar se há dados gerados
if [ ! -d "$DATA_DIR" ] || [ -z "$(ls -A $DATA_DIR/*.txt 2>/dev/null)" ]; then
    echo "❌ Nenhum dado encontrado em $DATA_DIR"
    echo "Execute primeiro: ./fault-tolerance/scripts/generate_data.sh"
    exit 1
fi

echo_info "Arquivos locais encontrados:"
ls -lh $DATA_DIR/*.txt

# Limpar diretório HDFS anterior
echo ""
echo_info "Limpando diretório HDFS anterior..."
docker exec hadoop-master hdfs dfs -rm -r -f $HDFS_DIR

# Criar diretório no HDFS
echo_info "Criando diretório no HDFS: $HDFS_DIR"
docker exec hadoop-master hdfs dfs -mkdir -p $HDFS_DIR

# Upload dos arquivos
echo ""
echo_info "Fazendo upload dos arquivos para HDFS..."

for file in $DATA_DIR/*.txt; do
    filename=$(basename "$file")
    echo_info "Uploading: $filename"
    docker cp "$file" hadoop-master:/tmp/
    docker exec hadoop-master hdfs dfs -put -f "/tmp/$filename" "$HDFS_DIR/"
    docker exec hadoop-master rm -f "/tmp/$filename"
done

# Verificar upload
echo ""
echo_title "Verificação do Upload"

echo_info "Arquivos no HDFS:"
docker exec hadoop-master hdfs dfs -ls $HDFS_DIR

echo ""
echo_info "Estatísticas do HDFS:"
docker exec hadoop-master hdfs dfs -du -h $HDFS_DIR

echo ""
echo_info "Análise de blocos:"
docker exec hadoop-master hdfs fsck $HDFS_DIR -files -blocks | head -30

echo ""
echo_title "Upload concluído!"
echo "Dados prontos em: $HDFS_DIR"
