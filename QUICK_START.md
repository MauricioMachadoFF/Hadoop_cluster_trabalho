# Guia Rápido - Cluster Hadoop

## Início Rápido (5 minutos)

### 1. Iniciar o Cluster

```bash
docker-compose up -d
```

Aguarde ~30 segundos para inicialização completa.

### 2. Verificar Status

```bash
docker-compose ps
```

Todos os 3 containers devem estar "Up".

### 3. Acessar Interfaces Web

- **HDFS NameNode**: http://localhost:9870
- **YARN ResourceManager**: http://localhost:8088
- **JobHistory Server**: http://localhost:19888

### 4. Verificar Cluster

```bash
# Ver DataNodes conectados
docker exec hadoop-master hdfs dfsadmin -report

# Ver NodeManagers ativos
docker exec hadoop-master yarn node -list
```

Deve mostrar 2 DataNodes e 2 NodeManagers.

### 5. Executar Exemplo WordCount

```bash
# Copiar arquivos para container
docker cp examples/wordcount hadoop-master:/tmp/

# Executar job
docker exec hadoop-master bash -c "
  cd /tmp/wordcount
  chmod +x *.py *.sh
  ./run_wordcount.sh
"
```

### 6. Ver Resultados

O script mostrará os resultados automaticamente. Você também pode:

```bash
# Ver resultados manualmente
docker exec hadoop-master hdfs dfs -cat /user/root/wordcount/output/part-*

# Top 10 palavras
docker exec hadoop-master bash -c "
  hdfs dfs -cat /user/root/wordcount/output/part-* | sort -t$'\t' -k2 -nr | head -10
"
```

## 📚 Componentes do Projeto

Este projeto está dividido em três componentes principais, cada um abordando um aspecto diferente do Apache Hadoop:

### 1️⃣ Montagem de um Cluster Hadoop Básico (Configuração Básica)

**Objetivo:** Configurar e executar um cluster Hadoop funcional com Docker.

**Localização:**
- `docker-compose.yml` - Orquestração dos containers
- `hadoop-config/` - Arquivos de configuração do Hadoop
- `start-master.sh` e `start-worker.sh` - Scripts de inicialização

**O que foi implementado:**
- ✅ 1 nó master (NameNode + ResourceManager + JobHistory)
- ✅ 2 nós workers (DataNode + NodeManager)
- ✅ Interfaces web de monitoramento (portas 9870, 8088, 19888)
- ✅ HDFS com fator de replicação 2
- ✅ YARN configurado com 2GB por NodeManager
- ✅ MapReduce com JobHistory Server

**Como usar:**
```bash
# Iniciar cluster
docker-compose up -d

# Verificar status
docker exec hadoop-master hdfs dfsadmin -report
docker exec hadoop-master yarn node -list

# Acessar interfaces
# HDFS: http://localhost:9870
# YARN: http://localhost:8088
# JobHistory: http://localhost:19888
```

**Documentação:** Ver `README.md` para detalhes completos da arquitetura.

---

### 2️⃣ Teste de Comportamento do Framework Hadoop

**Objetivo:** Demonstrar como diferentes configurações impactam performance e comportamento do HDFS, YARN e MapReduce.

**Localização:** `tests/`

**5 Testes Implementados:**

1. **test1_replication.sh** - Fator de replicação HDFS (1, 2, 3)
   - Impacto no uso de disco
   - Distribuição de blocos entre DataNodes
   - Trade-off entre segurança e espaço

2. **test2_yarn_memory.sh** - Memória YARN (1GB, 2GB, 4GB)
   - Número de containers simultâneos
   - Performance de jobs
   - Utilização de recursos

3. **test3_scheduler_queues.sh** - Filas do Capacity Scheduler
   - Single queue vs multiple queues (high/default/low)
   - Priorização de jobs
   - Isolamento de recursos

4. **test4_block_size.sh** - Tamanho de blocos HDFS (64MB, 128MB, 256MB)
   - Número de map tasks geradas
   - Overhead de metadados no NameNode
   - Performance de I/O

5. **test5_mapreduce_memory.sh** - Memória de containers MapReduce
   - Memória para mappers e reducers (256MB, 512MB, 1024MB)
   - Paralelismo vs consumo de recursos
   - Otimização de performance

**Como usar:**
```bash
# Executar teste individual
./tests/scripts/test1_replication.sh all

# Executar todos os testes (~35-40 minutos)
./tests/run_all_tests.sh

# Gerar relatório consolidado
./tests/generate_report.sh
```

**Resultados:** Arquivos salvos em `tests/results/` com métricas detalhadas e análise comparativa.

**Documentação:** Ver `tests/README.md` e `tests/TESTING_GUIDE.md` para detalhes de cada teste.

---

### 3️⃣ Teste de Tolerância a Falhas e Performance

**Objetivo:** Avaliar resiliência do Hadoop sob condições adversas e medir capacidade de recuperação.

**Localização:** `fault-tolerance/`

**4 Cenários de Teste:**

1. **Baseline** - Performance sem falhas
   - Cluster completo (2 workers)
   - Execução normal de WordCount
   - Estabelece linha de base de tempo (~3-4 min)

2. **Worker Failure** - Falha de 1 worker durante execução
   - Remove hadoop-worker1 após 30s
   - Testa recuperação automática do YARN
   - Job deve completar com ~20-40% mais tempo

3. **Scale Up** - Adição dinâmica de worker
   - Inicia com 1 worker apenas
   - Adiciona worker2 após 30s
   - Demonstra elasticidade do cluster

4. **Multiple Failures** - Falhas múltiplas (catastrófico)
   - Remove ambos workers progressivamente
   - Job deve FALHAR
   - Identifica limites de tolerância

**Scripts disponíveis:**
- `generate_data.sh` - Gera dataset de 500MB+ para jobs longos
- `upload_data.sh` - Upload para HDFS com verificação
- `monitor_job.sh` - Monitora jobs em tempo real
- `run_fault_test.sh` - Orquestra os 4 testes
- `generate_report.sh` - Relatório consolidado com análise

**Como usar:**
```bash
# 1. Gerar dados de teste
./fault-tolerance/scripts/generate_data.sh

# 2. Upload para HDFS
./fault-tolerance/scripts/upload_data.sh

# 3. Executar testes
./fault-tolerance/scripts/run_fault_test.sh all

# 4. Gerar relatório
./fault-tolerance/scripts/generate_report.sh
```

**Métricas coletadas:**
- Tempo de execução e recuperação
- Taxa de sucesso/falha
- Comportamento do ResourceManager
- Logs detalhados de cada cenário

**Documentação:** Ver `fault-tolerance/README.md` para análise completa dos resultados esperados.

---

## 🎯 Fluxo Recomendado de Execução

Para executar o projeto completo na ordem correta:

```bash
# Passo 1: Montar cluster básico
docker-compose up -d
docker exec hadoop-master hdfs dfsadmin -report  # Verificar

# Passo 2: Executar testes de comportamento
./tests/run_all_tests.sh                        # ~35-40 min
./tests/generate_report.sh                      # Relatório

# Passo 3: Testes de tolerância a falhas
./fault-tolerance/scripts/generate_data.sh      # Preparar dados
./fault-tolerance/scripts/upload_data.sh        # Upload HDFS
./fault-tolerance/scripts/run_fault_test.sh all # Executar testes
./fault-tolerance/scripts/generate_report.sh    # Relatório
```

**Tempo total estimado:** ~50-60 minutos para todos os testes

---

## Comandos Úteis

### Gerenciar Cluster

```bash
# Iniciar
docker-compose up -d

# Parar
docker-compose down

# Parar e remover dados
docker-compose down -v

# Ver logs
docker logs hadoop-master
docker logs hadoop-worker1

# Reiniciar
docker-compose restart
```

### Trabalhar com HDFS

```bash
# Acessar container master
docker exec -it hadoop-master bash

# Criar diretório
hdfs dfs -mkdir -p /user/root/meudir

# Upload arquivo
hdfs dfs -put arquivo.txt /user/root/meudir/

# Listar arquivos
hdfs dfs -ls /user/root/

# Ver conteúdo
hdfs dfs -cat /user/root/meudir/arquivo.txt

# Download arquivo
hdfs dfs -get /user/root/meudir/arquivo.txt ./

# Remover arquivo
hdfs dfs -rm /user/root/meudir/arquivo.txt

# Remover diretório
hdfs dfs -rm -r /user/root/meudir
```

### Executar Jobs MapReduce

```bash
# Job WordCount built-in
docker exec hadoop-master bash -c "
  echo 'hello world hello hadoop' > /tmp/input.txt
  hdfs dfs -mkdir -p /input
  hdfs dfs -put /tmp/input.txt /input/
  hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
    wordcount /input /output
  hdfs dfs -cat /output/part-*
"
```

### Monitorar Jobs

```bash
# Listar aplicações YARN
docker exec hadoop-master yarn application -list

# Status de uma aplicação
docker exec hadoop-master yarn application -status <APPLICATION_ID>

# Ver logs de aplicação
docker exec hadoop-master yarn logs -applicationId <APPLICATION_ID>
```

## Estrutura do Projeto

```
trabalho_hadoop/
├── docker-compose.yml              # Configuração do cluster
├── hadoop-config/                  # Arquivos de configuração
│   ├── core-site.xml              # Configurações gerais
│   ├── hdfs-site.xml              # HDFS
│   ├── yarn-site.xml              # YARN
│   ├── mapred-site.xml            # MapReduce
│   └── workers                    # Lista de workers
├── examples/
│   └── wordcount/                 # Exemplo WordCount
│       ├── mapper.py
│       ├── reducer.py
│       ├── run_wordcount.sh
│       └── README.md
├── README.md                       # Documentação completa
└── QUICK_START.md                 # Este guia
```

## Recursos do Cluster

- **Nós**: 1 master + 2 workers
- **Memória YARN**: 4 GB total (2 GB/worker)
- **CPUs**: 4 vCPUs (2/worker)
- **Replicação HDFS**: 2 réplicas

## Solução Rápida de Problemas

### DataNodes não conectam

```bash
# Reiniciar cluster
docker-compose restart

# Ver logs
docker logs hadoop-master
docker logs hadoop-worker1
```

### Job falha

1. Acesse http://localhost:8088
2. Clique no job
3. Veja logs nos containers

### Limpar tudo

```bash
# Parar e remover volumes
docker-compose down -v

# Limpar sistema Docker
docker system prune -a --volumes

# Reiniciar
docker-compose up -d
```

## Próximos Passos

1. ✅ Cluster funcionando
2. ✅ Exemplo WordCount executado
3. 📝 Criar seu próprio job MapReduce
4. 📝 Processar datasets maiores
5. 📝 Experimentar com múltiplos reducers
6. 📝 Implementar outros algoritmos (sorting, join, etc.)

## Recursos Adicionais

- **README.md**: Documentação completa
- **examples/wordcount/README.md**: Detalhes do exemplo
- Interfaces web para monitoramento
- Logs em tempo real via `docker logs`

## Entrega do Trabalho

Para documentar sua entrega, inclua:

1. ✅ Arquivos de configuração (`hadoop-config/`)
2. ✅ Docker Compose configurado
3. ✅ Screenshots das interfaces web
4. ✅ Exemplo de job executado
5. ✅ Documentação dos arquivos

Tire screenshots de:
- http://localhost:9870 (HDFS com 2 DataNodes)
- http://localhost:8088 (YARN com job executado)
- http://localhost:19888 (JobHistory)
- Saída do comando `hdfs dfsadmin -report`
- Resultado do WordCount

Boa sorte! 🚀
