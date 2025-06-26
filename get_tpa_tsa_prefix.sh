#!/bin/bash
##################################################
# Developed by Andrea Ghelfi 2022.04.18
# Updated by Andrea Ghelfi 2025.4.3
# Part of ddbj_sakura2DB
# TPA-TSA prefix, at103
# 
##################################################
BASE="/home/w3const/mssassist"

function exec_process () {
    #pwd > ~/temp_sakura2DB/workdir.txt
    USER=$(whoami)
    PGDATABASE="w-actual"
    PGPORT=54305
    PGHOST="a011"

    lines=`wc -l $HOME/temp_sakura2DB/input_ids.txt | cut -f1 -d " "`
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $USER -t -A -F"," -c "SELECT accession FROM accession WHERE accession LIKE 'Y%' ORDER BY accession DESC LIMIT 1;" | sed -E 's/[^A-Za-z]//g' > $HOME/temp_sakura2DB/last_prefix_actual.txt
    PGDATABASE="w-test"
    PGHOST="a012"
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $USER -t -A -F"," -c "SELECT accession FROM accession WHERE accession LIKE 'Y%' ORDER BY accession DESC LIMIT 1;" | sed -E 's/[^A-Za-z]//g' > $HOME/temp_sakura2DB/last_prefix_test.txt
    
    cat ~/temp_sakura2DB/last_prefix_test.txt ~/temp_sakura2DB/last_prefix_actual.txt | sort | tail -n1 > ~/temp_sakura2DB/last_prefix.txt
    last_prefix=`cat ~/temp_sakura2DB/last_prefix.txt | cut -c1-4 `
    # version:
    echo "Default version 01. Confirm version (y/n)?"
    read answer1
    form_ans1=`echo ${answer1^^}`
    if [[ ${form_ans1} = "Y" ]]; then
      awk -v var1="$last_prefix" -v var2="$lines" '$1 == var1 {for(i=1; i<=var2; i++) {getline; print $1 "01"}}' ${BASE}/tsunami/tpa_tsa_all.txt > ~/temp_sakura2DB/next_prefix.txt
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
      awk -v var1="$last_prefix" -v var2="$lines" -v var3="$ver" '$1 == var1 {for(i=1; i<=var2; i++) {getline; print $1 var3}}' ${BASE}/tsunami/tpa_tsa_all.txt > ~/temp_sakura2DB/next_prefix.txt
    fi
    paste -d"\t" ~/temp_sakura2DB/next_prefix.txt ~/temp_sakura2DB/input_ids.txt > ~/temp_sakura2DB/prefix_input_ids.txt
    echo "The current database is: "$PGDATABASE

}
EXEC_HOST1="tsunami-cytosine"
CURRENT_HOST=$(hostname)

if [[ "$CURRENT_HOST" == "$EXEC_HOST1" ]]; then
    echo "Querying TSUNAMIDB..."
    exec_process
else
    echo "This is TPA-TSA data and here is $CURRENT_HOST, please login on tsunami-cytosine."
fi
