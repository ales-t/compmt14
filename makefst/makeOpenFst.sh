#!/bin/bash

DIR="out"

mkdir -P $DIR
./makefst.pl --prefix="$DIR/"


fstcompile --isymbols=$DIR/isyms.1.txt --osymbols=$DIR/osyms.1.txt $DIR/text.1.txt $DIR/binary.1.fst

fstdraw --isymbols=$DIR/isyms.1.txt --osymbols=$DIR/osyms.1.txt $DIR/binary.1.fst $DIR/binary.1.dot

dot -Tps $DIR/binary.1.dot >$DIR/binary.ps

ps2pdf $DIR/binary.ps
