#!/bin/bash
g++ -std=c++17 \
    -g -fsanitize=address \
    -I./mupdf/include \
    -L./mupdf/build/release \
    -lmupdf -lmupdf-third \
    -o extract_test extract_test.cpp
