#!/bin/bash
# Script para gerar relatório consolidado dos testes

REPORT_FILE="tests/results/full_report.md"

cat > $REPORT_FILE <<'EOF'
# Relatório Consolidado - Testes de Comportamento do Hadoop

**Data de Execução:** $(date)
**Cluster:** 1 Master + 2 Workers (Docker)
**Versão Hadoop:** 3.3.6

---

## Sumário Executivo

Este relatório apresenta os resultados de 5 testes que demonstram como alterações nas configurações do Hadoop impactam o comportamento do cluster nos seguintes aspectos:

1. **HDFS**: Sistema de arquivos distribuído
2. **YARN**: Escalonamento e gerenciamento de recursos
3. **MapReduce**: Execução de aplicações distribuídas

---

## Metodologia

Cada teste seguiu o padrão:
1. **Baseline**: Medição com configuração padrão
2. **Variação**: Alteração específica na configuração
3. **Medição**: Coleta de métricas de impacto
4. **Análise**: Comparação e conclusões

---

## Teste 1: Fator de Replicação HDFS

### Objetivo
Avaliar o impacto do fator de replicação na utilização de espaço e disponibilidade dos dados.

### Configurações Testadas

| Teste | Replicação | Espaço Esperado | Disponibilidade |
|-------|------------|-----------------|-----------------|
| Baseline | 2 | 2x | Média |
| Variação 1 | 1 | 1x | Baixa |
| Variação 2 | 3 | 3x | Alta |

### Resultados

**Ver arquivo detalhado:** `tests/results/test1_results.txt`

### Análise

- **Replicação = 1**:
  - ✓ Menor uso de disco
  - ✗ Risco de perda de dados
  - ⚠️ Não recomendado para produção

- **Replicação = 2**:
  - ✓ Balanceamento entre espaço e disponibilidade
  - ✓ Tolerância a 1 falha de nó

- **Replicação = 3**:
  - ✓ Alta disponibilidade
  - ✓ Tolerância a 2 falhas simultâneas
  - ✗ Maior uso de disco

### Conclusões

O fator de replicação é um trade-off crítico entre:
- Utilização de espaço em disco
- Disponibilidade e confiabilidade dos dados
- Velocidade de escrita (mais réplicas = mais tempo)

---

## Teste 2: Alocação de Memória YARN

### Objetivo
Avaliar como limites de memória afetam a capacidade do cluster de executar jobs.

### Configurações Testadas

| Teste | Memória/Node | Max Container | Containers Esperados |
|-------|--------------|---------------|---------------------|
| Baseline | 2048 MB | 2048 MB | ~4 |
| Variação 1 | 1024 MB | 1024 MB | ~2 |
| Variação 2 | 4096 MB | 4096 MB | ~8 |

### Resultados

**Ver arquivo detalhado:** `tests/results/test2_results.txt`

### Análise

- **1024 MB**:
  - ✗ Capacidade reduzida de executar jobs
  - ✗ Possível rejeição de aplicações
  - ✓ Maior controle de recursos

- **2048 MB** (Baseline):
  - ✓ Balanceamento adequado
  - ✓ Múltiplos jobs simultâneos

- **4096 MB**:
  - ✓ Maior paralelismo
  - ✓ Jobs maiores podem executar
  - ⚠️ Requer mais recursos físicos

### Conclusões

A configuração de memória YARN determina diretamente:
- Número de containers que podem executar simultaneamente
- Tamanho máximo de jobs que podem ser aceitos
- Taxa de utilização do cluster

---

## Teste 3: Múltiplas Filas no Capacity Scheduler

### Objetivo
Demonstrar como múltiplas filas permitem priorização e isolamento de jobs.

### Configurações Testadas

| Teste | Filas | Distribuição | Priorização |
|-------|-------|--------------|-------------|
| Baseline | 1 (default) | 100% | FIFO |
| Variação | 3 (high/default/low) | 50%/30%/20% | Por fila |

### Resultados

**Ver arquivo detalhado:** `tests/results/test3_results.txt`

### Análise

- **Fila Única**:
  - ✓ Simplicidade
  - ✗ Sem priorização
  - ✗ Jobs críticos podem esperar

- **Múltiplas Filas**:
  - ✓ Priorização de jobs críticos
  - ✓ Isolamento de recursos
  - ✓ SLA garantido por fila
  - ✓ Melhor para ambientes multi-tenant

### Conclusões

Múltiplas filas são essenciais para:
- Ambientes com diferentes tipos de workloads
- Garantir SLAs diferenciados
- Evitar que jobs de baixa prioridade bloqueiem jobs críticos

---

## Teste 4: Tamanho de Blocos HDFS

### Objetivo
Avaliar o impacto do tamanho de blocos no número de splits MapReduce e carga no NameNode.

### Configurações Testadas

| Teste | Block Size | Blocos (200MB) | Map Tasks |
|-------|------------|----------------|-----------|
| Variação 1 | 64 MB | ~4 | ~4 |
| Baseline | 128 MB | ~2 | ~2 |
| Variação 2 | 256 MB | ~1 | ~1 |

### Resultados

**Ver arquivo detalhado:** `tests/results/test4_results.txt`

### Análise

- **64 MB**:
  - ✓ Mais paralelismo (mais map tasks)
  - ✗ Mais metadados no NameNode
  - ⚠️ Overhead de gerenciamento

- **128 MB** (Baseline):
  - ✓ Balanceamento padrão

- **256 MB**:
  - ✓ Menos metadados
  - ✗ Menos paralelismo
  - ✓ Melhor para arquivos grandes

### Conclusões

O tamanho de bloco deve ser escolhido baseado em:
- Tamanho típico dos arquivos
- Necessidade de paralelismo
- Capacidade do NameNode (memória)

---

## Teste 5: Memória dos Containers MapReduce

### Objetivo
Avaliar como a memória dos containers impacta a performance e paralelismo de jobs.

### Configurações Testadas

| Teste | Map Memory | Reduce Memory | Paralelismo | Performance |
|-------|------------|---------------|-------------|-------------|
| Variação 1 | 256 MB | 256 MB | Alto | Lenta |
| Baseline | 512 MB | 512 MB | Médio | Normal |
| Variação 2 | 1024 MB | 1024 MB | Baixo | Rápida |

### Resultados

**Ver arquivo detalhado:** `tests/results/test5_results.txt`

### Análise

- **256 MB**:
  - ✓ Mais containers simultâneos
  - ✗ Risco de OOM (Out of Memory)
  - ✗ Performance individual menor

- **512 MB** (Baseline):
  - ✓ Balanceamento adequado

- **1024 MB**:
  - ✓ Melhor performance individual
  - ✗ Menos paralelismo
  - ✓ Adequado para jobs com grandes datasets

### Conclusões

A memória dos containers MapReduce é um trade-off entre:
- Performance individual das tasks
- Número de tasks executando simultaneamente
- Risco de falhas por falta de memória

---

## Conclusões Gerais

### Principais Aprendizados

1. **Não existe configuração única ideal**: Cada workload requer ajustes específicos
2. **Trade-offs são inevitáveis**: Otimizar um aspecto geralmente impacta outro
3. **Monitoramento é essencial**: Métricas permitem ajustes informados
4. **Testes são necessários**: Configurações devem ser validadas com workloads reais

### Recomendações

1. **Iniciar com defaults**: Hadoop vem com configurações balanceadas
2. **Monitorar continuamente**: Usar interfaces web e métricas
3. **Ajustar gradualmente**: Mudanças incrementais permitem isolar impactos
4. **Documentar mudanças**: Manter histórico de configurações e resultados

### Trade-offs Observados

| Aspecto | Aumentar | Diminuir |
|---------|----------|----------|
| **Replicação HDFS** | + Disponibilidade<br>- Espaço | + Espaço<br>- Disponibilidade |
| **Memória YARN** | + Paralelismo<br>- Recursos | + Recursos<br>- Paralelismo |
| **Filas Scheduler** | + Flexibilidade<br>- Complexidade | + Simplicidade<br>- Controle |
| **Block Size** | + Eficiência NameNode<br>- Paralelismo | + Paralelismo<br>- Overhead |
| **Memória MR** | + Performance<br>- Paralelismo | + Paralelismo<br>- Performance |

---

## Interfaces Web de Monitoramento

Durante os testes, as seguintes interfaces foram utilizadas:

- **HDFS NameNode**: http://localhost:9870
  - Visualização de blocos e replicação
  - Status dos DataNodes
  - Utilização de espaço

- **YARN ResourceManager**: http://localhost:8088
  - Status das filas
  - Aplicações em execução
  - Alocação de recursos

- **MapReduce JobHistory**: http://localhost:19888
  - Histórico de jobs
  - Métricas de performance
  - Análise de falhas

---

## Anexos

### Arquivos de Resultados

- `test1_results.txt`: Detalhes do teste de replicação
- `test2_results.txt`: Detalhes do teste de memória YARN
- `test3_results.txt`: Detalhes do teste de filas
- `test4_results.txt`: Detalhes do teste de block size
- `test5_results.txt`: Detalhes do teste de memória MapReduce

### Configurações Utilizadas

Todas as configurações de teste estão em: `tests/configurations/`

---

**Relatório gerado em:** $(date)
**Ferramentas:** Hadoop 3.3.6, Docker, Bash Scripts
EOF

# Substituir placeholders
sed -i.bak "s/\$(date)/$(date)/" $REPORT_FILE
rm -f $REPORT_FILE.bak

echo "Relatório consolidado gerado: $REPORT_FILE"
