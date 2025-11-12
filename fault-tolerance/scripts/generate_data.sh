#!/bin/bash
# Gerador de Dados para Testes de Tolerância a Falhas

OUTPUT_DIR="fault-tolerance/data"
TARGET_SIZE_MB=${1:-500}  # Tamanho padrão: 500MB

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_title() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

echo_title "Gerador de Dados para Testes de Tolerância a Falhas"

mkdir -p $OUTPUT_DIR

# Palavras para gerar texto aleatório (simulando conteúdo literário)
WORDS=(
    "hadoop" "mapreduce" "distributed" "computing" "cluster" "data" "processing"
    "parallel" "scalable" "fault" "tolerance" "resilience" "performance" "big"
    "analytics" "framework" "yarn" "hdfs" "namenode" "datanode" "replication"
    "block" "metadata" "storage" "memory" "cpu" "network" "latency" "throughput"
    "algorithm" "optimization" "efficiency" "resource" "allocation" "scheduling"
    "container" "application" "job" "task" "mapper" "reducer" "shuffle" "sort"
    "partition" "combiner" "input" "output" "split" "record" "key" "value"
    "system" "architecture" "design" "implementation" "deployment" "monitoring"
    "logging" "debugging" "testing" "validation" "verification" "quality"
    "reliability" "availability" "consistency" "integrity" "security" "access"
    "the" "a" "an" "and" "or" "but" "in" "on" "at" "to" "for" "of" "with"
    "from" "by" "about" "as" "into" "through" "during" "before" "after" "above"
    "is" "are" "was" "were" "be" "been" "being" "have" "has" "had" "do" "does"
    "this" "that" "these" "those" "here" "there" "where" "when" "how" "why"
    "can" "could" "may" "might" "must" "should" "would" "will" "shall"
)

# Função para gerar uma linha de texto aleatória
generate_line() {
    local word_count=$((RANDOM % 20 + 5))  # 5-25 palavras por linha
    local line=""

    for ((i=0; i<word_count; i++)); do
        local word_index=$((RANDOM % ${#WORDS[@]}))
        line="$line ${WORDS[$word_index]}"
    done

    echo "$line" | sed 's/^ //'
}

# Função para gerar arquivo com tamanho específico
generate_file() {
    local filename=$1
    local target_mb=$2
    local target_bytes=$((target_mb * 1024 * 1024))

    echo_info "Gerando arquivo: $filename (${target_mb}MB)"

    local current_size=0
    local lines=0

    > "$OUTPUT_DIR/$filename"  # Criar arquivo vazio

    while [ $current_size -lt $target_bytes ]; do
        generate_line >> "$OUTPUT_DIR/$filename"
        lines=$((lines + 1))

        # Atualizar tamanho a cada 1000 linhas
        if [ $((lines % 1000)) -eq 0 ]; then
            current_size=$(stat -f%z "$OUTPUT_DIR/$filename" 2>/dev/null || stat -c%s "$OUTPUT_DIR/$filename" 2>/dev/null)
            local current_mb=$((current_size / 1024 / 1024))
            echo -ne "\rProgresso: ${current_mb}MB / ${target_mb}MB (${lines} linhas)"
        fi
    done

    echo ""
    echo_info "Arquivo criado: $filename"
    ls -lh "$OUTPUT_DIR/$filename"
}

# Gerar múltiplos arquivos para distribuir a carga
echo_info "Tamanho total alvo: ${TARGET_SIZE_MB}MB"
echo_info "Criando múltiplos arquivos para melhor distribuição..."

# Dividir em arquivos de ~100MB cada para melhor paralelismo
NUM_FILES=$((TARGET_SIZE_MB / 100))
if [ $NUM_FILES -lt 1 ]; then
    NUM_FILES=1
fi

SIZE_PER_FILE=$((TARGET_SIZE_MB / NUM_FILES))

echo_info "Gerando $NUM_FILES arquivos de ~${SIZE_PER_FILE}MB cada"

for ((i=1; i<=NUM_FILES; i++)); do
    generate_file "dataset_part_${i}.txt" $SIZE_PER_FILE
done

echo ""
echo_title "Resumo dos Dados Gerados"

echo "Arquivos criados:"
ls -lh $OUTPUT_DIR/

echo ""
total_size=$(du -sh $OUTPUT_DIR | cut -f1)
file_count=$(ls -1 $OUTPUT_DIR/*.txt 2>/dev/null | wc -l)
echo_info "Total: $file_count arquivos, ${total_size}"

echo ""
echo_info "Análise de conteúdo:"
total_lines=$(cat $OUTPUT_DIR/*.txt | wc -l)
total_words=$(cat $OUTPUT_DIR/*.txt | wc -w)
echo "  - Linhas totais: $total_lines"
echo "  - Palavras totais: $total_words"

echo ""
echo_title "Dados prontos para upload!"
echo "Execute: ./fault-tolerance/scripts/upload_data.sh"
