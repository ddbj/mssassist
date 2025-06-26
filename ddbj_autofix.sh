#!/bin/bash

BASE="/home/w3const/mssassist"
SIMG="sing-mssassist.sif"
BD="${PWD}:/data,${BASE}/step2:/mnt"

# singularity run --bind .:/data ${BASE}/ddbj_autofix_v1.4.sif
singularity exec --bind ${BD} ${BASE}/${SIMG} /mnt/ddbj_autofix_sing.sh
# Run jParser
if [[ ! -f Rfixed/ERROR_MISSING_ANN_FILES.tsv && ! -f Rfixed/ERROR_MISSING_FASTA_FILES.tsv ]]; then
  echo "Do you like to run jParser and transChecker) (Yes or No)?"
  read answer
  form_ans=`echo ${answer^^}`
  if [ $form_ans = "Y" ] || [ $form_ans = "YES" ]; then
    cd Rfixed
    declare -i len_check_fasta=`ls *.fasta 2> /dev/null | wc -l`
    if [ $len_check_fasta -gt 0 ]; then
      jParser="${BASE}/ag_jParser_transChecker.sh"
      nohup bash ${jParser} </dev/null &>jParser_transChecker.log &
      jParser_pid=$!
      echo "jParser_transChecker PID: "${jParser_pid}
    fi
    wait ${jParser_pid}
    # Read output of transChecker and jParser
    check_errors="${BASE}/check_output_jParser_transChecker.sh"
    bash ${check_errors}
    cd ../
  fi
fi
