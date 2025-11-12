# WordCount - Exemplo MapReduce com Hadoop Streaming

Este exemplo demonstra como executar um job MapReduce usando Hadoop Streaming com Python.

## Arquivos

- `mapper.py`: Mapper que lê linhas e emite pares (palavra, 1)
- `reducer.py`: Reducer que soma as contagens para cada palavra
- `input_sample.txt`: Arquivo de exemplo com texto sobre Hadoop
- `run_wordcount.sh`: Script automatizado para executar o job

## Como Executar

### Método 1: Script Automatizado (Recomendado)

```bash
# Copiar arquivos para o container
docker cp examples/wordcount hadoop-master:/tmp/

# Executar dentro do container
docker exec -it hadoop-master bash -c "
  cd /tmp/wordcount
  chmod +x *.py run_wordcount.sh
  ./run_wordcount.sh
"
```

### Método 2: Passo a Passo Manual

#### 1. Preparar arquivos no container

```bash
# Copiar arquivos
docker cp examples/wordcount hadoop-master:/tmp/

# Acessar container
docker exec -it hadoop-master bash
cd /tmp/wordcount
chmod +x mapper.py reducer.py
```

#### 2. Preparar dados no HDFS

```bash
# Criar diretório de entrada
hdfs dfs -mkdir -p /user/root/wordcount/input

# Copiar arquivo para HDFS
hdfs dfs -put input_sample.txt /user/root/wordcount/input/

# Verificar
hdfs dfs -ls /user/root/wordcount/input/
```

#### 3. Executar job MapReduce

```bash
hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-*.jar \
    -input /user/root/wordcount/input \
    -output /user/root/wordcount/output \
    -mapper mapper.py \
    -reducer reducer.py \
    -file mapper.py \
    -file reducer.py
```

#### 4. Ver resultados

```bash
# Ver todos os resultados
hdfs dfs -cat /user/root/wordcount/output/part-*

# Ver top 20 palavras mais frequentes
hdfs dfs -cat /user/root/wordcount/output/part-* | sort -t$'\t' -k2 -nr | head -20
```

## Explicação do Código

### Mapper (mapper.py)

O mapper:
1. Lê cada linha da entrada padrão (stdin)
2. Converte para minúsculas e remove pontuação
3. Divide em palavras
4. Emite cada palavra com contagem 1: `palavra\t1`

```python
for word in words:
    print(f"{word}\t1")
```

### Reducer (reducer.py)

O reducer:
1. Recebe pares (palavra, contagem) ordenados por palavra
2. Agrupa por palavra usando `groupby`
3. Soma as contagens de cada grupo
4. Emite o total: `palavra\ttotal`

```python
for word, group in groupby(read_mapper_output(sys.stdin), itemgetter(0)):
    total_count = sum(count for _, count in group)
    print(f"{word}\t{total_count}")
```

## Hadoop Streaming

Hadoop Streaming permite usar qualquer executável (Python, Ruby, etc.) como mapper/reducer:

- **Entrada**: stdin
- **Saída**: stdout
- **Formato**: `chave\tvalor` (separado por tab)
- **Ordenação**: Hadoop ordena automaticamente entre map e reduce

## Testando Localmente

Você pode testar o pipeline localmente antes de executar no Hadoop:

```bash
# Testar pipeline completo
cat input_sample.txt | python3 mapper.py | sort | python3 reducer.py

# Testar apenas mapper
cat input_sample.txt | python3 mapper.py

# Testar apenas reducer (com dados ordenados)
cat input_sample.txt | python3 mapper.py | sort | python3 reducer.py
```

## Monitoramento

Durante a execução, monitore o job em:

- **YARN ResourceManager**: http://localhost:8088
  - Clique na aplicação para ver detalhes
  - Veja logs de containers
  - Monitore progresso

- **MapReduce JobHistory**: http://localhost:19888
  - Veja jobs completados
  - Analise contadores
  - Verifique tempo de execução

## Saída Esperada

O job deve processar o texto e contar as palavras. Exemplo de saída:

```
hadoop	5
data	3
mapreduce	3
distributed	2
processing	2
apache	2
...
```

## Troubleshooting

### Erro: "Permission denied"

```bash
chmod +x mapper.py reducer.py
```

### Erro: "Output directory already exists"

```bash
hdfs dfs -rm -r /user/root/wordcount/output
```

### Job falha sem mensagem clara

Verifique logs no YARN UI (http://localhost:8088):
1. Clique na aplicação
2. Clique em "logs"
3. Veja stderr/stdout dos containers

### Python não encontrado

Certifique-se que a primeira linha dos scripts é:
```python
#!/usr/bin/env python3
```

## Próximos Passos

Experimente modificar o exemplo:

1. **Adicionar filtros**: Ignore palavras comuns (stop words)
2. **Múltiplos arquivos**: Adicione mais arquivos no diretório de entrada
3. **Combiner**: Adicione um combiner para otimizar
4. **Partitioner customizado**: Distribua palavras de forma específica
5. **Múltiplos reducers**: Use mais reducers para paralelizar

Exemplo com 3 reducers:
```bash
hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-*.jar \
    -input /user/root/wordcount/input \
    -output /user/root/wordcount/output \
    -mapper mapper.py \
    -reducer reducer.py \
    -file mapper.py \
    -file reducer.py \
    -numReduceTasks 3
```

## Referências

- [Hadoop Streaming Documentation](https://hadoop.apache.org/docs/stable/hadoop-streaming/HadoopStreaming.html)
- [MapReduce Tutorial](https://hadoop.apache.org/docs/stable/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapReduceTutorial.html)
