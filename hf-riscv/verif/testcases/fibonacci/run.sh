#!/bin/bash

directory=$PWD

cd ../../../../software/
make clean
make fib
cp code.txt $directory

cd $directory
cp ../../boot.txt .
cp ../../sim_testcase.do .
vsim -c -do sim_testcase.do
