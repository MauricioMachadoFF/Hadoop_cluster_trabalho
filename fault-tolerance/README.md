# Teste de Tolerância a Falhas e Performance

Este framework testa a capacidade de resiliência e recuperação do Apache Hadoop sob condições adversas, incluindo falhas de nós e mudanças dinâmicas na topologia do cluster.

## 📋 Objetivo

Avaliar o comportamento do Hadoop quando:
- Nós workers falham durante a execução de jobs
- Novos nós são adicionados dinamicamente (scale up)
- Múltiplas falhas simultâneas ocorrem
- Medir impacto na performance e capacidade de recuperação

## 🏗️ Estrutura do Framework

```
fault-tolerance/
├── scripts/
│   ├── generate_data.sh      # Gera datasets de teste (500MB+)
│   ├── upload_data.sh         # Upload dos dados para HDFS
│   ├── monitor_job.sh         # Monitora jobs em tempo real
│   └── run_fault_test.sh      # Orquestra os testes de falha
├── data/                      # Dados gerados localmente
├── results/                   # Resultados dos testes
└── monitoring/                # Logs de monitoramento
```

## 🚀 Guia de Execução Rápida

### 1. Preparar Dados de Teste

Gerar dataset de 500MB (padrão):
```bash
./fault-tolerance/scripts/generate_data.sh
```

Ou especificar tamanho customizado (em MB):
```bash
./fault-tolerance/scripts/generate_data.sh 1000  # 1GB
```

### 2. Upload para HDFS

```bash
./fault-tolerance/scripts/upload_data.sh
```

Verifica que os dados foram distribuídos corretamente no cluster.

### 3. Executar Testes de Tolerância a Falhas

**Teste Individual:**
```bash
./fault-tolerance/scripts/run_fault_test.sh baseline          # Teste 1
./fault-tolerance/scripts/run_fault_test.sh worker-failure    # Teste 2
./fault-tolerance/scripts/run_fault_test.sh scale-up          # Teste 3
./fault-tolerance/scripts/run_fault_test.sh multiple-failures # Teste 4
```

**Todos os Testes:**
```bash
./fault-tolerance/scripts/run_fault_test.sh all
```

## 📊 Cenários de Teste

### Teste 1: BASELINE - Performance Sem Falhas
**Objetivo:** Estabelecer linha de base de performance

**Configuração:**
- Cluster completo (1 master + 2 workers)
- Execução normal de WordCount
- Dataset: 500MB+

**Métricas Coletadas:**
- Tempo total de execução
- Throughput (MB/s)
- Número de containers utilizados
- Status de todos os nós

**Resultado Esperado:**
- Job completa com sucesso
- Todos os nós ativos durante toda execução
- Baseline de tempo para comparação

---

### Teste 2: Falha de 1 Worker Durante Execução
**Objetivo:** Testar recuperação de falha de nó único

**Configuração:**
- Inicia com cluster completo (2 workers)
- Após 30s de execução: **remove hadoop-worker1**
- Job continua com apenas 1 worker

**Métricas Coletadas:**
- Tempo até detecção da falha
- Tempo de recuperação
- Tasks perdidas e reexecutadas
- Impacto no tempo total de execução

**Resultado Esperado:**
- YARN detecta falha do NodeManager
- Tasks em execução no worker1 são reprocessadas
- Job completa com sucesso (porém mais lento)
- Demonstra failover automático

---

### Teste 3: Scale Up - Adicionar Worker Durante Execução
**Objetivo:** Testar elasticidade do cluster

**Configuração:**
- Inicia com apenas 1 worker (hadoop-worker1)
- Após 30s de execução: **adiciona hadoop-worker2**
- Job passa a utilizar recursos adicionais

**Métricas Coletadas:**
- Tempo até novo nó ser reconhecido
- Redistribuição de tasks
- Melhoria de performance após scale up

**Resultado Esperado:**
- Novo NodeManager se registra no ResourceManager
- Novas tasks são alocadas no novo nó
- Job completa mais rápido que execução com 1 worker
- Demonstra adição dinâmica de recursos

---

### Teste 4: Falhas Múltiplas (Cenário Catastrófico)
**Objetivo:** Testar limite de tolerância a falhas

**Configuração:**
- Inicia com cluster completo (2 workers)
- Após 20s: **remove hadoop-worker1**
- Após mais 20s: **remove hadoop-worker2**
- Master fica sem workers disponíveis

**Métricas Coletadas:**
- Tempo até falha total do job
- Comportamento do ResourceManager
- Logs de erro e tentativas de recuperação

**Resultado Esperado:**
- Job FALHA após timeout
- ResourceManager reporta falta de recursos
- Logs mostram tentativas de retry
- Demonstra limites da tolerância a falhas

---

## 📈 Análise de Resultados

### Arquivos de Resultado

Após cada teste, os seguintes arquivos são gerados em `fault-tolerance/results/`:

```
test1_baseline.txt          # Métricas do baseline
test1_monitor.log           # Log detalhado do monitoramento

test2_worker_failure.txt    # Métricas de falha de worker
test2_monitor.log           # Log do comportamento sob falha

test3_scale_up.txt          # Métricas de scale up
test3_monitor.log           # Log do comportamento com adição de nó

test4_multiple_failures.txt # Métricas de falhas múltiplas
test4_monitor.log           # Log do colapso do cluster
```

### Métricas Importantes

**Performance:**
- Tempo total de execução (segundos)
- Comparação com baseline (% mais lento/rápido)
- Throughput de processamento

**Resiliência:**
- Tempo de detecção de falha (segundos)
- Tempo de recuperação (segundos)
- Taxa de sucesso de reprocessamento
- Número de tentativas de retry

**Recursos:**
- Número de nós ativos durante execução
- Containers em execução
- Utilização de memória YARN
- Distribuição de blocos HDFS

### Comparação Entre Testes

| Teste | Workers | Condição | Tempo Esperado | Status |
|-------|---------|----------|----------------|--------|
| 1. Baseline | 2 | Normal | ~3-4 min | ✓ SUCCESS |
| 2. Worker Failure | 2→1 | Falha em T+30s | ~5-6 min | ✓ SUCCESS (recovered) |
| 3. Scale Up | 1→2 | Adição em T+30s | ~4-5 min | ✓ SUCCESS |
| 4. Multiple Failures | 2→0 | Falhas T+20s, T+40s | ~1-2 min | ✗ FAILED |

## 🔍 Monitoramento em Tempo Real

O script `monitor_job.sh` fornece visualização em tempo real:

```
==== Monitor de Job Hadoop ====

Application ID: application_1234567890_0001
Estado: RUNNING
Progresso: 45%
Tempo decorrido: 2m 15s

Status do Cluster:
Total Nodes: 2

-------------------------------------------------
[21:30:45] Progress: 45% | State: RUNNING | Elapsed: 135s | Total Nodes: 2
[21:31:00] Progress: 52% | State: RUNNING | Elapsed: 150s | Total Nodes: 1
⚠ [21:31:05] Nó hadoop-worker1 removido - detectada falha
[21:31:20] Progress: 58% | State: RUNNING | Elapsed: 180s | Total Nodes: 1
```

## 🛠️ Troubleshooting

### Problema: Job não inicia
```bash
# Verificar se os dados estão no HDFS
docker exec hadoop-master hdfs dfs -ls /fault-tolerance/input

# Verificar NodeManagers disponíveis
docker exec hadoop-master yarn node -list
```

### Problema: Script não captura Application ID
```bash
# Aumentar sleep para captura do ID
# Editar run_fault_test.sh linha 56: sleep 10 → sleep 20
```

### Problema: Workers não se recuperam
```bash
# Restaurar manualmente
docker-compose start hadoop-worker1 hadoop-worker2
sleep 30

# Verificar logs
docker logs hadoop-worker1
docker logs hadoop-worker2
```

## 📝 Limpeza

Remover dados e resultados:
```bash
# Limpar dados locais
rm -rf fault-tolerance/data/*.txt

# Limpar HDFS
docker exec hadoop-master hdfs dfs -rm -r /fault-tolerance

# Limpar resultados
rm -rf fault-tolerance/results/*.txt
rm -rf fault-tolerance/monitoring/*.log
```

## 🎯 Conclusões Esperadas

Este framework demonstra:

1. **Tolerância a Falhas YARN:**
   - NodeManager pode falhar sem derrubar job
   - Tasks são automaticamente reexecutadas
   - ResourceManager mantém estado consistente

2. **Elasticidade:**
   - Cluster aceita novos nós dinamicamente
   - Recursos são redistribuídos automaticamente
   - Melhoria de performance com scale up

3. **Limites:**
   - Perda de todos workers causa falha do job
   - Overhead de recuperação impacta performance
   - Trade-off entre resiliência e eficiência

4. **HDFS Resiliência:**
   - Replicação protege contra perda de dados
   - Blocos sobrevivem a falhas de DataNode
   - Leitura continua de réplicas alternativas
