#!/bin/bash
##################################################
# Developed by Andrea Ghelfi 2022.04.18
# Updated by Andrea Ghelfi 2025.4.3
# Part of ddbj_sakura2DB
# TPA-WGS prefix
# 
##################################################
BASE="/home/w3const/mssassist"

function exec_process () {
    # pwd > ~/temp_sakura2DB/workdir.txt
    USER=$(whoami)
    PGDATABASE="w-actual"
    PGPORT=54305
    PGHOST="a011"
    
    lines=`wc -l $HOME/temp_sakura2DB/input_ids.txt | cut -f1 -d " "`
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $USER -t -A -F"," -c "SELECT accession FROM accession WHERE ((LENGTH(accession) = 15 AND accession LIKE 'E%') 
    OR (LENGTH(accession) = 12 AND accession LIKE 'E%' AND NOT EXISTS (SELECT 1 FROM accession WHERE LENGTH(accession) = 15 AND accession LIKE 'E%'))) ORDER BY accession DESC LIMIT 1;" | sed -E 's/[^A-Za-z]//g' > $HOME/temp_sakura2DB/last_prefix_actual_conv.txt
    # umss
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $USER -t -A -F"," -c "SELECT * FROM (SELECT DISTINCT prefix,set_version FROM umss_ann_entry WHERE accession LIKE 'E%' ORDER BY prefix DESC LIMIT 1) AS subquery WHERE subquery.prefix ~ '^[A-Za-z]{6}';" | awk '{sub(",",""); print $1$2}' > $HOME/temp_sakura2DB/last_prefix_actual_umss.txt
    # -test
    PGDATABASE="w-test"
    PGHOST="a012"
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $USER -t -A -F"," -c "SELECT accession FROM accession WHERE ((LENGTH(accession) = 15 AND accession LIKE 'E%') 
    OR (LENGTH(accession) = 12 AND accession LIKE 'E%' AND NOT EXISTS (SELECT 1 FROM accession WHERE LENGTH(accession) = 15 AND accession LIKE 'E%'))) ORDER BY accession DESC LIMIT 1;" | sed -E 's/[^A-Za-z]//g' > $HOME/temp_sakura2DB/last_prefix_test_conv.txt
    # umss
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $USER -t -A -F"," -c "SELECT * FROM (SELECT DISTINCT prefix,set_version FROM umss_ann_entry WHERE accession LIKE 'E%' ORDER BY prefix DESC LIMIT 1) AS subquery WHERE subquery.prefix ~ '^[A-Za-z]{6}';" | awk '{sub(",",""); print $1$2}' > $HOME/temp_sakura2DB/last_prefix_test_umss.txt
    echo "The current database is: "$PGDATABASE
}

EXEC_HOST1="tsunami-cytosine"
CURRENT_HOST=$(hostname)

if [[ "$CURRENT_HOST" == "$EXEC_HOST1" ]]; then
    echo "Querying TSUNAMIDB..."
    exec_process
else
    echo "This is TPA-WGS data and here is $CURRENT_HOST, please login on tsunami-cytosine."
fi
