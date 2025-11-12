#!/bin/bash
# Script para executar todos os testes de comportamento do Hadoop

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_title() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
}

echo_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

echo_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

echo_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Criar diretório de resultados
mkdir -p tests/results

echo_title "Suite de Testes de Comportamento do Hadoop"
echo_info "Data: $(date)"
echo_info "Estes testes irão:"
echo_info "  1. Testar impacto do fator de replicação HDFS"
echo_info "  2. Testar impacto da alocação de memória YARN"
echo_info "  3. Testar impacto de múltiplas filas no scheduler"
echo_info "  4. Testar impacto do tamanho de blocos HDFS"
echo_info "  5. Testar impacto da memória dos containers MapReduce"
echo ""
echo_info "Tempo estimado: ~30-40 minutos"
echo ""
read -p "Deseja continuar? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo_info "Testes cancelados."
    exit 0
fi

# Verificar se cluster está rodando
echo_info "Verificando se o cluster está ativo..."
if ! docker ps | grep -q hadoop-master; then
    echo_error "Cluster não está rodando!"
    echo_info "Execute: docker-compose up -d"
    exit 1
fi
echo_success "Cluster está ativo"

# Tornar scripts executáveis
chmod +x tests/scripts/*.sh

# ========================================
# TESTE 1: Replicação HDFS
# ========================================
echo_title "TESTE 1/5: Fator de Replicação HDFS"
echo_info "Testando impacto de diferentes fatores de replicação..."

if ./tests/scripts/test1_replication.sh all; then
    echo_success "Teste 1 concluído"
else
    echo_error "Teste 1 falhou"
fi

echo_info "Aguardando 10 segundos antes do próximo teste..."
sleep 10

# ========================================
# TESTE 2: Memória YARN
# ========================================
echo_title "TESTE 2/5: Alocação de Memória YARN"
echo_info "Testando impacto de diferentes configurações de memória..."

if ./tests/scripts/test2_yarn_memory.sh all; then
    echo_success "Teste 2 concluído"
else
    echo_error "Teste 2 falhou"
fi

echo_info "Aguardando 10 segundos antes do próximo teste..."
sleep 10

# ========================================
# TESTE 3: Filas do Scheduler
# ========================================
echo_title "TESTE 3/5: Múltiplas Filas no Capacity Scheduler"
echo_info "Testando impacto de múltiplas filas com prioridades..."

if ./tests/scripts/test3_scheduler_queues.sh all; then
    echo_success "Teste 3 concluído"
else
    echo_error "Teste 3 falhou"
fi

echo_info "Aguardando 10 segundos antes do próximo teste..."
sleep 10

# ========================================
# TESTE 4: Tamanho de Blocos
# ========================================
echo_title "TESTE 4/5: Tamanho de Blocos HDFS"
echo_info "Testando impacto de diferentes tamanhos de bloco..."

if ./tests/scripts/test4_block_size.sh all; then
    echo_success "Teste 4 concluído"
else
    echo_error "Teste 4 falhou"
fi

echo_info "Aguardando 10 segundos antes do próximo teste..."
sleep 10

# ========================================
# TESTE 5: Memória MapReduce
# ========================================
echo_title "TESTE 5/5: Memória dos Containers MapReduce"
echo_info "Testando impacto de diferentes configurações de memória MR..."

if ./tests/scripts/test5_mapreduce_memory.sh all; then
    echo_success "Teste 5 concluído"
else
    echo_error "Teste 5 falhou"
fi

# ========================================
# FINALIZAÇÃO
# ========================================
echo_title "Todos os Testes Concluídos!"

echo_success "Resultados salvos em:"
echo "  - tests/results/test1_results.txt (Replicação HDFS)"
echo "  - tests/results/test2_results.txt (Memória YARN)"
echo "  - tests/results/test3_results.txt (Filas Scheduler)"
echo "  - tests/results/test4_results.txt (Tamanho Blocos)"
echo "  - tests/results/test5_results.txt (Memória MapReduce)"

echo ""
echo_info "Gerando relatório consolidado..."
if ./tests/generate_report.sh; then
    echo_success "Relatório gerado: tests/results/full_report.md"
else
    echo_error "Erro ao gerar relatório"
fi

echo ""
echo_title "Próximos Passos"
echo "1. Revise os resultados em tests/results/"
echo "2. Tire screenshots das interfaces web:"
echo "   - HDFS: http://localhost:9870"
echo "   - YARN: http://localhost:8088"
echo "   - JobHistory: http://localhost:19888"
echo "3. Analise o relatório consolidado: tests/results/full_report.md"
echo "4. Documente suas observações e conclusões"

echo ""
echo_success "Testes finalizados com sucesso!"
