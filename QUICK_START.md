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
