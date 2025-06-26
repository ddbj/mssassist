#!/bin/bash
##################################################
# sakura2DB actual 
# Updated by Andrea Ghelfi 2025.4.3
# Part of ddbj_sakura2DB
# 
##################################################

function exec_process () {
  HOST=`hostname`
  echo "This is $HOST"
  PGHOST="a011"
  echo "This is PGHOST: "$PGHOST
  PGDATABASE="e-actual"
  echo "The current database is: "$PGDATABASE

  # # add docker version (v2.1)
  # mv ~/temp_sakura2DB/run_sakura2DB.sh ~/temp_sakura2DB/temp_run_sakura2DB.sh
  # ACCOUNT=$(whoami)
  # DCOMPOSE="/home/w3const/tsunami-exec-compose"
  # DEXEC="docker compose -f ${DCOMPOSE}/compose.yaml --env-file ${DCOMPOSE}/.env.${PGDATABASE} --env-file ${DCOMPOSE}/.env.${ACCOUNT} run --rm tsunami-tools"
  # awk -v var1="${DEXEC}" '{sub("./sakura2DB", var1 " ./sakura2DB"); print $0}' ~/temp_sakura2DB/temp_run_sakura2DB.sh > ~/temp_sakura2DB/run_sakura2DB.sh
  
  bash ~/temp_sakura2DB/run_sakura2DB.sh
}
EXEC_HOST1="tsunami-adenine"
CURRENT_HOST=$(hostname)

if [[ "$CURRENT_HOST" == "$EXEC_HOST1" ]]; then
    echo "Running Sakura2DB ..."
    exec_process
else
    echo "This is $CURRENT_HOST, please login on tsunami-adenine."
fi
