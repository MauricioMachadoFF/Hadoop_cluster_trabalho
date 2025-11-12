# Testes de Comportamento do Hadoop

Esta pasta contém uma suite completa de testes para demonstrar o impacto de alterações nas configurações do Hadoop.

## 🎯 Objetivos

Demonstrar como mudanças nas configurações afetam:
- **HDFS**: Sistema de arquivos distribuído
- **YARN**: Escalonamento e alocação de recursos
- **MapReduce**: Execução de aplicações

## 📋 Testes Disponíveis

| # | Teste | Descrição | Tempo Estimado |
|---|-------|-----------|----------------|
| 1 | Replicação HDFS | Impacto do fator de replicação (1, 2, 3) | ~5 min |
| 2 | Memória YARN | Impacto dos limites de memória (1GB, 2GB, 4GB) | ~8 min |
| 3 | Filas Scheduler | Impacto de múltiplas filas com prioridades | ~6 min |
| 4 | Tamanho de Blocos | Impacto do block size (64MB, 128MB, 256MB) | ~7 min |
| 5 | Memória MapReduce | Impacto da memória dos containers (256MB, 512MB, 1GB) | ~8 min |

**Total**: ~35-40 minutos

## 🚀 Execução Rápida

### Executar Todos os Testes

```bash
./tests/run_all_tests.sh
```

### Executar Teste Individual

```bash
# Teste 1 - Replicação
./tests/scripts/test1_replication.sh all

# Teste 2 - Memória YARN
./tests/scripts/test2_yarn_memory.sh all

# Teste 3 - Filas
./tests/scripts/test3_scheduler_queues.sh all

# Teste 4 - Block Size
./tests/scripts/test4_block_size.sh all

# Teste 5 - Memória MapReduce
./tests/scripts/test5_mapreduce_memory.sh all
```

### Gerar Relatório

```bash
./tests/generate_report.sh
cat tests/results/full_report.md
```

## 📊 Resultados

Após execução, os resultados estarão em:

```
tests/results/
├── test1_results.txt       # Replicação HDFS
├── test2_results.txt       # Memória YARN
├── test3_results.txt       # Filas Scheduler
├── test4_results.txt       # Block Size
├── test5_results.txt       # Memória MapReduce
└── full_report.md          # Relatório consolidado
```

## 📖 Documentação Completa

Ver: `tests/TESTING_GUIDE.md`

## ⚙️ Estrutura

```
tests/
├── README.md                    # Este arquivo
├── TESTING_GUIDE.md             # Guia completo de testes
├── run_all_tests.sh             # Executa todos os testes
├── generate_report.sh           # Gera relatório consolidado
├── scripts/                     # Scripts de teste
│   ├── test1_replication.sh
│   ├── test2_yarn_memory.sh
│   ├── test3_scheduler_queues.sh
│   ├── test4_block_size.sh
│   └── test5_mapreduce_memory.sh
├── configurations/              # Configurações de teste
│   ├── test1/
│   ├── test2/
│   ├── test3/
│   ├── test4/
│   └── test5/
└── results/                     # Resultados dos testes
```

## 🔍 Monitoramento

Durante os testes, monitore via interfaces web:

- **HDFS**: http://localhost:9870
- **YARN**: http://localhost:8088
- **JobHistory**: http://localhost:19888

## ⚠️ Pré-requisitos

1. Cluster Hadoop rodando:
   ```bash
   docker-compose up -d
   ```

2. Aguardar cluster estar pronto (~40 segundos)

3. Verificar status:
   ```bash
   docker exec hadoop-master hdfs dfsadmin -report
   docker exec hadoop-master yarn node -list
   ```

## 💡 Dicas

1. **Execute os testes individualmente primeiro** para entender cada um
2. **Tire screenshots** das interfaces web mostrando os impactos
3. **Documente observações** em cada teste
4. **Compare resultados** entre diferentes configurações
5. **Analise os trade-offs** de cada mudança

## 📝 Para o Relatório

Inclua na documentação do trabalho:

1. ✅ Descrição de cada teste
2. ✅ Configurações alteradas
3. ✅ Resultados observados (com métricas)
4. ✅ Screenshots das interfaces web
5. ✅ Análise dos impactos
6. ✅ Conclusões e trade-offs identificados

## 🔄 Restaurar Configurações

Cada script tem opção de restaurar:

```bash
./tests/scripts/test1_replication.sh restore
./tests/scripts/test2_yarn_memory.sh restore
# etc...
```

Ou use o script principal com `all` que restaura automaticamente.

## 📚 Referências

- [Hadoop Configuration Guide](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html)
- [YARN Capacity Scheduler](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/CapacityScheduler.html)
- [HDFS Architecture](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html)
