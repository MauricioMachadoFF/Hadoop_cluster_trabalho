# Guia de Testes de Comportamento do Hadoop

Este documento descreve 5 testes que demonstram como alterações nas configurações do Hadoop impactam o comportamento do cluster.

## Objetivo

Demonstrar o impacto de mudanças nas configurações do Hadoop em:
- **YARN**: Escalonamento de processos e alocação de recursos
- **HDFS**: Sistema de arquivos distribuído
- **MapReduce**: Execução de aplicações

## Estrutura dos Testes

Cada teste segue o padrão:
1. **Estado Inicial**: Medição do comportamento atual
2. **Mudança**: Alteração específica na configuração
3. **Impacto**: Medição e análise do efeito
4. **Reversão**: Retorno ao estado original (opcional)

---

## Teste 1: Fator de Replicação do HDFS

### Configuração Alterada
- **Arquivo**: `hdfs-site.xml`
- **Propriedade**: `dfs.replication`
- **Mudança**: 2 → 1 → 3

### Objetivo
Demonstrar como o fator de replicação impacta:
- Utilização de espaço em disco
- Disponibilidade de dados
- Tempo de escrita

### Comandos para Teste

```bash
# Estado inicial (replication=2)
./tests/test1_replication.sh baseline

# Teste com replication=1
./tests/test1_replication.sh test_rep1

# Teste com replication=3
./tests/test1_replication.sh test_rep3

# Ver resultados
cat tests/results/test1_results.txt
```

### Impactos Esperados

| Replicação | Espaço Usado | Disponibilidade | Velocidade Escrita |
|------------|--------------|-----------------|-------------------|
| 1          | Menor (1x)   | Baixa          | Rápida            |
| 2          | Média (2x)   | Média          | Normal            |
| 3          | Maior (3x)   | Alta           | Mais lenta        |

---

## Teste 2: Alocação de Memória YARN

### Configuração Alterada
- **Arquivo**: `yarn-site.xml`
- **Propriedades**:
  - `yarn.nodemanager.resource.memory-mb`
  - `yarn.scheduler.maximum-allocation-mb`

### Objetivo
Demonstrar como limites de memória afetam:
- Número de containers simultâneos
- Capacidade de executar jobs
- Rejeição de aplicações

### Comandos para Teste

```bash
# Estado inicial (2048 MB)
./tests/test2_yarn_memory.sh baseline

# Teste com memória reduzida (1024 MB)
./tests/test2_yarn_memory.sh test_low

# Teste com memória aumentada (4096 MB)
./tests/test2_yarn_memory.sh test_high

# Ver resultados
cat tests/results/test2_results.txt
```

### Impactos Esperados

| Memória Total | Containers Max | Jobs Simultâneos | Taxa Rejeição |
|---------------|----------------|------------------|---------------|
| 1024 MB       | ~2             | 1-2              | Alta          |
| 2048 MB       | ~4             | 2-4              | Média         |
| 4096 MB       | ~8             | 4-8              | Baixa         |

---

## Teste 3: Filas do Capacity Scheduler

### Configuração Alterada
- **Arquivo**: `capacity-scheduler.xml`
- **Mudança**: Adicionar múltiplas filas com prioridades diferentes

### Objetivo
Demonstrar como filas afetam:
- Priorização de jobs
- Compartilhamento de recursos
- Garantias de capacidade

### Comandos para Teste

```bash
# Estado inicial (1 fila default)
./tests/test3_scheduler_queues.sh baseline

# Criar 3 filas (high, default, low)
./tests/test3_scheduler_queues.sh test_multi_queue

# Submeter jobs em diferentes filas
./tests/test3_scheduler_queues.sh test_priority

# Ver resultados
cat tests/results/test3_results.txt
```

### Impactos Esperados

| Configuração | Filas | Isolamento | Priorização |
|--------------|-------|------------|-------------|
| 1 fila       | 1     | Não        | FIFO        |
| 3 filas      | 3     | Sim        | Por fila    |

---

## Teste 4: Tamanho de Blocos HDFS

### Configuração Alterada
- **Arquivo**: `hdfs-site.xml`
- **Propriedade**: `dfs.blocksize`
- **Mudança**: 128MB → 64MB → 256MB

### Objetivo
Demonstrar como o tamanho de bloco impacta:
- Número de blocos gerados
- Carga no NameNode (metadados)
- Número de map tasks

### Comandos para Teste

```bash
# Estado inicial (128 MB)
./tests/test4_block_size.sh baseline

# Teste com blocos pequenos (64 MB)
./tests/test4_block_size.sh test_small

# Teste com blocos grandes (256 MB)
./tests/test4_block_size.sh test_large

# Ver resultados
cat tests/results/test4_results.txt
```

### Impactos Esperados

Para arquivo de 1 GB:

| Block Size | Num Blocos | Map Tasks | Metadados NameNode |
|------------|------------|-----------|-------------------|
| 64 MB      | 16         | 16        | Alto              |
| 128 MB     | 8          | 8         | Médio             |
| 256 MB     | 4          | 4         | Baixo             |

---

## Teste 5: Memória dos Containers MapReduce

### Configuração Alterada
- **Arquivo**: `mapred-site.xml`
- **Propriedades**:
  - `mapreduce.map.memory.mb`
  - `mapreduce.reduce.memory.mb`

### Objetivo
Demonstrar como a memória dos containers afeta:
- Performance de execução
- Número de jobs simultâneos
- Taxa de falhas (OOM)

### Comandos para Teste

```bash
# Estado inicial (512 MB map/reduce)
./tests/test5_mapreduce_memory.sh baseline

# Teste com pouca memória (256 MB)
./tests/test5_mapreduce_memory.sh test_low

# Teste com muita memória (1024 MB)
./tests/test5_mapreduce_memory.sh test_high

# Ver resultados
cat tests/results/test5_results.txt
```

### Impactos Esperados

| Memória Map/Reduce | Performance | Paralelismo | Risco OOM |
|--------------------|-------------|-------------|-----------|
| 256 MB             | Mais lenta  | Alto        | Alto      |
| 512 MB             | Normal      | Médio       | Médio     |
| 1024 MB            | Mais rápida | Baixo       | Baixo     |

---

## Executar Todos os Testes

```bash
# Executar suite completa de testes
./tests/run_all_tests.sh

# Gerar relatório consolidado
./tests/generate_report.sh

# Ver relatório
cat tests/results/full_report.md
```

## Estrutura de Resultados

```
tests/
├── results/
│   ├── test1_results.txt       # Resultados do teste de replicação
│   ├── test2_results.txt       # Resultados do teste de memória YARN
│   ├── test3_results.txt       # Resultados do teste de filas
│   ├── test4_results.txt       # Resultados do teste de block size
│   ├── test5_results.txt       # Resultados do teste de memória MapReduce
│   └── full_report.md          # Relatório consolidado
├── configurations/
│   ├── test1/                  # Configs para teste 1
│   ├── test2/                  # Configs para teste 2
│   ├── test3/                  # Configs para teste 3
│   ├── test4/                  # Configs para teste 4
│   └── test5/                  # Configs para teste 5
└── scripts/
    ├── test1_replication.sh
    ├── test2_yarn_memory.sh
    ├── test3_scheduler_queues.sh
    ├── test4_block_size.sh
    └── test5_mapreduce_memory.sh
```

## Métricas Coletadas

Para cada teste, coletamos:

1. **HDFS**:
   - Capacidade configurada
   - Espaço usado
   - Número de blocos
   - Fator de replicação aplicado

2. **YARN**:
   - Memória total disponível
   - Memória alocada
   - Número de containers ativos
   - Filas configuradas

3. **MapReduce**:
   - Tempo de execução
   - Número de map tasks
   - Número de reduce tasks
   - Taxa de sucesso

4. **Cluster**:
   - CPU usage
   - Network I/O
   - Disk I/O

## Dicas para Análise

1. **Compare os resultados** entre configurações diferentes
2. **Observe trade-offs**: performance vs recursos
3. **Documente comportamentos inesperados**
4. **Tire screenshots** das interfaces web mostrando o impacto
5. **Analise logs** quando houver falhas

## Interfaces Web para Monitoramento

- **HDFS**: http://localhost:9870 - Ver utilização de blocos e replicação
- **YARN**: http://localhost:8088 - Ver alocação de recursos e filas
- **JobHistory**: http://localhost:19888 - Ver performance de jobs

## Próximos Passos

Após executar os testes:
1. Compile os resultados em um relatório
2. Inclua screenshots das interfaces web
3. Analise os trade-offs observados
4. Documente lições aprendidas
