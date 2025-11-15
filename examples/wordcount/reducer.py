#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Reducer para WordCount usando Hadoop Streaming
Lê pares (palavra, 1) do stdin e soma as contagens
"""
import sys
from itertools import groupby
from operator import itemgetter

def reducer():
    """
    Lê pares palavra-contagem da entrada padrão (já ordenados por palavra)
    e emite a contagem total para cada palavra
    """
    for word, group in groupby(read_mapper_output(sys.stdin), itemgetter(0)):
        total_count = sum(count for _, count in group)
        print("{0}\t{1}".format(word, total_count))

def read_mapper_output(file):
    """
    Lê a saída do mapper e converte para tuplas (palavra, contagem)
    """
    for line in file:
        # Remove espaços em branco
        line = line.strip()

        # Divide a linha em palavra e contagem
        if '\t' in line:
            word, count = line.split('\t', 1)
            try:
                yield word, int(count)
            except ValueError:
                # Ignora linhas malformadas
                continue

if __name__ == "__main__":
    reducer()
