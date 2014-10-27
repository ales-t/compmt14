#!/bin/bash

DIR="out_wmt14"
DB="../db/wmt14.ppdb.all.gz"
INPUT="../data/wmt14.stc.en"
#INPUT=data
PARA_WEIGHT=0.7

echo "MakeFST tool"
echo
echo "Setting:"
echo "   Out dir:           $DIR"
echo "   Database file:     $DB"
echo "   Paraphrase weight: $PARA_WEIGHT"
echo "   Input:             $INPUT"
echo

echo "Creating paraphrase FSTs.."

mkdir -p $DIR
cat $INPUT | ./makefst.pl --prefix="$DIR/" --weight="$PARA_WEIGHT" -p "$DB" --lines=`wc -l $INPUT`

echo "Normalizing scores.."

normalized=0
for file in $DIR/text.*.txt ; do
    normalized=$(($normalized+1))

    ./normalizeOFST.pl $file

    echo -ne "\r$normalized"
done
echo


indexes=`ls $DIR/text.*.txt | sed 's/\.txt//' | sed 's/.*\.//'`;


echo "Compiling FSTs.."

compiled=0
for i in $indexes ; do
    fstcompile --isymbols=$DIR/isyms.$i.txt --osymbols=$DIR/osyms.$i.txt $DIR/text.$i.txt.norm $DIR/binary.$i.fst

    compiled=$(($compiled+1))
    echo -ne "\r$compiled"
done
echo

if [ -z ENABLE_DRAWING ] ; then

    echo "Drawing"

    for i in $indexes ; do
        fstdraw --isymbols=$DIR/isyms.$i.txt --osymbols=$DIR/osyms.$i.txt $DIR/binary.$i.fst $DIR/binary.$i.dot
        dot -Tps $DIR/binary.$i.dot >$DIR/binary.$i.ps
    done

    echo "Converting to PDF"

    for i in $indexes ; do
        ps2pdf $DIR/binary.$i.ps
    done

fi

echo
echo "Done"
echo
