#!/bin/bash

DIR="out"
DB="../db/ppdb-1.0-s-m2o.gz"
PARA_WEIGHT=0.7

echo "MakeFST tool"
echo
echo "Setting:"
echo "   Out dir:           $DIR"
echo "   Database file:     $DB"
echo "   Paraphrase weight: $PARA_WEIGHT"
echo

echo "Creating paraphrase FSTs.."

mkdir -p $DIR
./makefst.pl --prefix="$DIR/" --weight="$PARA_WEIGHT" -p "$DB"

echo "Normalizing scores.."

for file in $DIR/text.*.txt ; do
    ./normalizeOFST.pl $file
done

indexes=`ls $DIR/text.*.txt | sed 's/\.txt//' | sed 's/.*\.//'`;

echo "Compiling FSTs.."


for i in $indexes ; do
    fstcompile --isymbols=$DIR/isyms.$i.txt --osymbols=$DIR/osyms.$i.txt $DIR/text.$i.txt.norm $DIR/binary.$i.fst
done


echo "Drawing"

for i in $indexes ; do
    fstdraw --isymbols=$DIR/isyms.$i.txt --osymbols=$DIR/osyms.$i.txt $DIR/binary.$i.fst $DIR/binary.$i.dot
    dot -Tps $DIR/binary.$i.dot >$DIR/binary.$i.ps
done

echo "Converting to PDF"

for i in $indexes ; do
    ps2pdf $DIR/binary.$i.ps
done

echo 
echo "Done"
echo
