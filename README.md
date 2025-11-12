# Cluster Hadoop - Configuração Básica

## Visão Geral

Este projeto implementa um cluster Hadoop básico utilizando Docker Compose, composto por:
- **1 Nó Master**: Executa NameNode, ResourceManager e JobHistory Server
- **2 Nós Workers**: Executam DataNode e NodeManager cada

## Arquitetura do Cluster

```
hadoop-master (Master Node)
├── NameNode (HDFS) - Porta 9870
├── ResourceManager (YARN) - Porta 8088
└── JobHistory Server - Porta 19888

hadoop-worker1 (Worker Node)
├── DataNode (HDFS)
└── NodeManager (YARN)

hadoop-worker2 (Worker Node)
├── DataNode (HDFS)
└── NodeManager (YARN)
```

## Interfaces Web de Monitoramento

Após iniciar o cluster, as seguintes interfaces estarão disponíveis:

- **HDFS NameNode UI**: http://localhost:9870
  - Monitora o estado do sistema de arquivos HDFS
  - Visualiza DataNodes conectados
  - Verifica espaço disponível e replicação de blocos

- **YARN ResourceManager UI**: http://localhost:8088
  - Monitora aplicações em execução
  - Visualiza recursos disponíveis no cluster
  - Acompanha jobs MapReduce

- **MapReduce JobHistory Server**: http://localhost:19888
  - Visualiza histórico de jobs completados
  - Analisa métricas de desempenho

## Estrutura de Arquivos

```
trabalho_hadoop/
├── docker-compose.yml          # Configuração do cluster Docker
├── hadoop-config/              # Arquivos de configuração do Hadoop
│   ├── core-site.xml          # Configurações centrais do Hadoop
│   ├── hdfs-site.xml          # Configurações do HDFS
│   ├── yarn-site.xml          # Configurações do YARN
│   ├── mapred-site.xml        # Configurações do MapReduce
│   └── workers                # Lista dos nós workers
├── examples/                   # Exemplos de jobs MapReduce
│   └── wordcount/             # Exemplo WordCount
└── README.md                   # Esta documentação
```

## Arquivos de Configuração

### 1. core-site.xml

Define configurações centrais do Hadoop:

**Propriedades principais:**
- `fs.defaultFS`: URI do sistema de arquivos HDFS (hdfs://hadoop-master:9000)
- `hadoop.tmp.dir`: Diretório para arquivos temporários
- `hadoop.http.staticuser.user`: Usuário padrão para interfaces web

### 2. hdfs-site.xml

Configurações específicas do HDFS:

**Propriedades principais:**
- `dfs.replication`: Fator de replicação (2, pois temos 2 workers)
- `dfs.namenode.name.dir`: Diretório de metadados do NameNode
- `dfs.datanode.data.dir`: Diretório de dados dos DataNodes
- `dfs.namenode.http-address`: Endereço da interface web (9870)
- `dfs.namenode.rpc-address`: Endereço RPC do NameNode
- `dfs.webhdfs.enabled`: Habilita API REST do HDFS

### 3. yarn-site.xml

Configurações do YARN para gerenciamento de recursos:

**Propriedades principais:**
- `yarn.resourcemanager.hostname`: Hostname do ResourceManager
- `yarn.resourcemanager.webapp.address`: Interface web (8088)
- `yarn.nodemanager.aux-services`: Serviços auxiliares (mapreduce_shuffle)
- `yarn.nodemanager.resource.memory-mb`: Memória por NodeManager (2048 MB)
- `yarn.nodemanager.resource.cpu-vcores`: CPUs virtuais por NodeManager (2)
- `yarn.scheduler.minimum-allocation-mb`: Memória mínima para containers (512 MB)
- `yarn.log-aggregation-enable`: Habilita agregação de logs

### 4. mapred-site.xml

Configurações do MapReduce:

**Propriedades principais:**
- `mapreduce.framework.name`: Framework de execução (yarn)
- `mapreduce.jobhistory.address`: Endereço do JobHistory Server
- `mapreduce.map.memory.mb`: Memória para map tasks (512 MB)
- `mapreduce.reduce.memory.mb`: Memória para reduce tasks (512 MB)
- `yarn.app.mapreduce.am.resource.mb`: Memória para Application Master (512 MB)

### 5. workers

Lista os hostnames dos nós workers:
```
hadoop-worker1
hadoop-worker2
```

## Como Usar

### Pré-requisitos

- Docker instalado
- Docker Compose instalado

### 1. Iniciar o Cluster

```bash
docker-compose up -d
```

Aguarde alguns segundos para os serviços iniciarem completamente.

### 2. Verificar Status dos Containers

```bash
docker-compose ps
```

Todos os 3 containers devem estar com status "Up".

### 3. Verificar Logs

```bash
# Logs do master
docker logs hadoop-master

# Logs dos workers
docker logs hadoop-worker1
docker logs hadoop-worker2
```

### 4. Acessar o Container Master

```bash
docker exec -it hadoop-master bash
```

### 5. Verificar HDFS

```bash
# Dentro do container master
hdfs dfsadmin -report
```

Deve mostrar 2 DataNodes conectados.

### 6. Testar HDFS - Criar Diretórios e Arquivos

```bash
# Criar diretório no HDFS
hdfs dfs -mkdir -p /user/root/input

# Criar arquivo de teste local
echo "Hello Hadoop World" > test.txt
echo "Hadoop MapReduce Example" >> test.txt

# Copiar para HDFS
hdfs dfs -put test.txt /user/root/input/

# Listar arquivos no HDFS
hdfs dfs -ls /user/root/input/

# Ver conteúdo
hdfs dfs -cat /user/root/input/test.txt
```

### 7. Executar Job MapReduce de Exemplo

O exemplo WordCount está disponível no diretório `examples/wordcount/`.

```bash
# Preparar dados de entrada
docker exec hadoop-master bash -c "
  echo 'Hello World Bye World' > /tmp/input1.txt
  echo 'Hello Hadoop Goodbye Hadoop' > /tmp/input2.txt
  hdfs dfs -mkdir -p /user/root/wordcount/input
  hdfs dfs -put /tmp/input1.txt /user/root/wordcount/input/
  hdfs dfs -put /tmp/input2.txt /user/root/wordcount/input/
"

# Executar WordCount
docker exec hadoop-master bash -c "
  hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /user/root/wordcount/input /user/root/wordcount/output
"

# Ver resultados
docker exec hadoop-master hdfs dfs -cat /user/root/wordcount/output/part-r-00000
```

### 8. Parar o Cluster

```bash
docker-compose down
```

Para remover também os volumes (dados serão perdidos):
```bash
docker-compose down -v
```

## Monitoramento via Interface Web

### HDFS - NameNode UI (http://localhost:9870)

- **Overview**: Status geral do cluster HDFS
- **Datanodes**: Lista de DataNodes e seu status
- **Utilities > Browse the file system**: Navegar no HDFS
- **Utilities > Logs**: Ver logs do NameNode

### YARN - ResourceManager UI (http://localhost:8088)

- **Cluster Metrics**: Métricas do cluster (memória, CPUs)
- **Nodes**: Status dos NodeManagers
- **Applications**: Aplicações em execução e histórico
- **Scheduler**: Visualização do scheduler

### MapReduce - JobHistory Server (http://localhost:19888)

- **Jobs**: Histórico de jobs MapReduce
- **Details**: Detalhes de execução de cada job
- **Counters**: Contadores e estatísticas

## Solução de Problemas

### DataNodes não conectam

1. Verifique os logs:
```bash
docker logs hadoop-worker1
docker logs hadoop-worker2
```

2. Verifique se o NameNode está rodando:
```bash
docker exec hadoop-master jps
```

Deve mostrar `NameNode` na lista.

### Jobs não executam

1. Verifique se NodeManagers estão conectados:
```bash
docker exec hadoop-master yarn node -list
```

2. Verifique logs do ResourceManager:
```bash
docker logs hadoop-master | grep -i resourcemanager
```

### Erro "No space left"

Limpe volumes antigos:
```bash
docker system prune -a --volumes
```

## Recursos do Cluster

- **Memória total YARN**: 4 GB (2 GB por worker)
- **CPUs virtuais**: 4 vCPUs (2 por worker)
- **Replicação HDFS**: 2 réplicas
- **Memória por container**: Mínimo 512 MB, Máximo 2048 MB

## Personalização

Para modificar recursos, edite `yarn-site.xml`:

```xml
<!-- Aumentar memória por NodeManager -->
<property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>4096</value>
</property>

<!-- Aumentar CPUs por NodeManager -->
<property>
    <name>yarn.nodemanager.resource.cpu-vcores</name>
    <value>4</value>
</property>
```

Após alterações, reinicie o cluster:
```bash
docker-compose restart
```

## Referências

- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/stable/)
- [HDFS Architecture](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html)
- [YARN Architecture](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/YARN.html)
- [MapReduce Tutorial](https://hadoop.apache.org/docs/stable/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapReduceTutorial.html)

## Notas Importantes

1. Este cluster é para fins educacionais/desenvolvimento
2. Não use em produção sem configurações adicionais de segurança
3. As permissões do HDFS estão desabilitadas para simplificar
4. Todos os serviços rodam como root (não recomendado para produção)
5. Os dados persistem nos volumes Docker até serem explicitamente removidos
