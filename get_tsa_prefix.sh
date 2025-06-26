#!/bin/bash
##################################################
# Developed by Andrea Ghelfi 2022.04.18
# Updated by Andrea Ghelfi 2025.3.19
# Part of ddbj_sakura2DB
# TSA prefix
# 
##################################################
BASE="/home/w3const/mssassist"

function exec_process () {
    pwd > ~/temp_sakura2DB/workdir.txt
    USER=$(whoami)
    PGDATABASE="e-actual"
    PGPORT=54304
    PGHOST="a011"
    lines=`wc -l ~/temp_sakura2DB/input_ids.txt | cut -f1 -d " "`
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $USER -t -A -F"," -c "SELECT accession FROM accession WHERE accession LIKE 'I%' ORDER BY accession DESC LIMIT 1;" | cut -c1-6  > ~/temp_sakura2DB/last_prefix_actual_conv.txt
    # umss
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $USER -t -A -F"," -c "SELECT DISTINCT prefix,set_version FROM umss_ann_entry WHERE accession LIKE 'I%' ORDER BY prefix DESC LIMIT 1;" | awk '{sub(",",""); print $1$2}' > ~/temp_sakura2DB/last_prefix_actual_umss.txt
    # -test
    PGDATABASE="e-test"
    PGHOST="a012"
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $USER -t -A -F"," -c "SELECT accession FROM accession WHERE accession LIKE 'I%' ORDER BY accession DESC LIMIT 1;" | cut -c1-6 > ~/temp_sakura2DB/last_prefix_test_conv.txt
    # umss
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $USER -t -A -F"," -c "SELECT DISTINCT prefix,set_version FROM umss_ann_entry WHERE accession LIKE 'I%' ORDER BY prefix DESC LIMIT 1;" | awk '{sub(",",""); print $1$2}' > ~/temp_sakura2DB/last_prefix_test_umss.txt
    # select last prefix
    cat ~/temp_sakura2DB/last_prefix_actual_conv.txt ~/temp_sakura2DB/last_prefix_actual_umss.txt ~/temp_sakura2DB/last_prefix_test_conv.txt ~/temp_sakura2DB/last_prefix_test_umss.txt | sort | tail -n1 > ~/temp_sakura2DB/last_prefix.txt
    last_prefix=`cat ~/temp_sakura2DB/last_prefix.txt | cut -c1-4 `
    # version:
    echo "Default version 01. Confirm version (y/n)?"
    read answer1
    form_ans1=`echo ${answer1^^}`
    if [[ ${form_ans1} = "Y" ]]; then
      awk -v var1="$last_prefix" -v var2="$lines" '$1 == var1 {for(i=1; i<=var2; i++) {getline; print $1 "01"}}' ${BASE}/tsunami/tsa_all.txt > ~/temp_sakura2DB/next_prefix.txt
    elif [[ ${form_ans1} = "N" ]]; then
      test_number='^[0-9]+$'
      echo "Enter version number (Example v.02, type: 2)"
      read answer2
      while ! [[ ${answer2} =~ ${test_number} ]] ; do
        echo "Enter version number:"
        read answer2
        while [[ ${answer2} -eq 0 || ${answer2} -gt 99 ]] ; do
          echo "Enter version number:"
          read answer2
        done
      done
      declare -i version=${answer2}
      if [[ ${version} -ge 1 && ${version} -le 9 ]]; then
        ver=0${version}
      else
        ver=${version}
      fi
      awk -v var1="$last_prefix" -v var2="$lines" -v var3="$ver" '$1 == var1 {for(i=1; i<=var2; i++) {getline; print $1 var3}}' ${BASE}/tsunami/tls_all.txt > ~/temp_sakura2DB/next_prefix.txt
    fi
    paste -d"\t" ~/temp_sakura2DB/next_prefix.txt ~/temp_sakura2DB/input_ids.txt > ~/temp_sakura2DB/prefix_input_ids.txt
    echo "The current database is: "$PGDATABASE
}
EXEC_HOST1="tsunami-adenine"
CURRENT_HOST=$(hostname)

if [[ "$CURRENT_HOST" == "$EXEC_HOST1" ]]; then
    echo "Querying TSUNAMIDB..."
    exec_process
else
    echo "This is TSA data and here is $CURRENT_HOST, please login on tsunami-adenine."
fi
