#!/bin/bash

python2 ./circuit-files/qasm2tex.py ./circuit-files/qcircuit.qasm > ./circuit-files/qcircuit.tex &&
latex -output-directory=./circuit-files ./circuit-files/qcircuit.tex > /dev/null &&
dvipdf ./circuit-files/qcircuit.dvi > /dev/null

echo "Output has been written to qcircuit.pdf"
