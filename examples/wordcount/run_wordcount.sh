#!/bin/bash
# Script para executar o job WordCount usando Hadoop Streaming

echo "=== WordCount MapReduce usando Hadoop Streaming ==="
echo ""

# Configurações
INPUT_DIR="/user/root/wordcount/input"
OUTPUT_DIR="/user/root/wordcount/output"
MAPPER="mapper.py"
REDUCER="reducer.py"

# Remove diretório de saída se existir
echo "1. Limpando diretório de saída anterior..."
hdfs dfs -rm -r -f $OUTPUT_DIR

# Cria diretório de entrada
echo "2. Criando diretório de entrada no HDFS..."
hdfs dfs -mkdir -p $INPUT_DIR

# Copia arquivo de entrada para HDFS
echo "3. Copiando arquivo de entrada para HDFS..."
hdfs dfs -put -f input_sample.txt $INPUT_DIR/

# Lista arquivos no HDFS
echo "4. Arquivos no HDFS:"
hdfs dfs -ls $INPUT_DIR

# Executa o job MapReduce usando Hadoop Streaming
echo ""
echo "5. Executando job MapReduce..."
echo ""

hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-*.jar \
    -input $INPUT_DIR \
    -output $OUTPUT_DIR \
    -mapper $MAPPER \
    -reducer $REDUCER \
    -file $MAPPER \
    -file $REDUCER

# Verifica resultado
if [ $? -eq 0 ]; then
    echo ""
    echo "=== Job concluído com sucesso! ==="
    echo ""
    echo "6. Resultados (top 20 palavras mais frequentes):"
    hdfs dfs -cat $OUTPUT_DIR/part-* | sort -t$'\t' -k2 -nr | head -20
    echo ""
    echo "7. Para ver todos os resultados:"
    echo "   hdfs dfs -cat $OUTPUT_DIR/part-*"
    echo ""
    echo "8. Para ver na interface web:"
    echo "   - HDFS: http://localhost:9870"
    echo "   - YARN: http://localhost:8088"
    echo "   - JobHistory: http://localhost:19888"
else
    echo ""
    echo "=== Erro ao executar o job ==="
    echo "Verifique os logs em: http://localhost:8088"
fi
