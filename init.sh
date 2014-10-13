#!/bin/bash
source init.cfg
db_dir="db"
mkdir $db_dir
for db in $dbs
do
	wget "${repo}${size}-${db}.gz" -P $db_dir
done
