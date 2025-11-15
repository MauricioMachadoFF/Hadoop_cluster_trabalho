#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Mapper para WordCount usando Hadoop Streaming
Lê linhas do stdin e emite pares (palavra, 1)
"""
import sys
import re

def mapper():
    """
    Lê linhas da entrada padrão e emite cada palavra com contagem 1
    """
    for line in sys.stdin:
        # Remove espaços em branco e converte para minúsculas
        line = line.strip().lower()

        # Remove pontuação e divide em palavras
        words = re.findall(r'\b\w+\b', line)

        # Emite cada palavra com contagem 1
        for word in words:
            if word:  # Ignora strings vazias
                print("{0}\t1".format(word))

if __name__ == "__main__":
    mapper()
