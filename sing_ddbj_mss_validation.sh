#!/bin/bash

BASE="/home/w3const/mssassist"
SIMG="sing-mssassist.sif"
BD="${PWD}:/data,${BASE}/tables:/srv,${BASE}/step1:/mnt"

# nohup singularity run --bind .:/data,${BASE}/tables:/srv ${BASE}/ddbj_mss_validation_v2.91.sif </dev/null &>sing_ddbj_mss_validation.log &
# sing_ddbj_mss=$!
# echo "singularity PID: "${sing_ddbj_mss}
# wait ${sing_ddbj_mss}
echo "Running format_ann_file, mss_validation, SVP, and common_check."
singularity exec --bind ${BD} ${BASE}/${SIMG} /mnt/ddbj_mss_validation_sing.sh &>sing_ddbj_mss_validation.log

# Run jParser
if [[ ! -f Rfixed/ERROR_MISSING_ANN_FILES.tsv && ! -f Rfixed/ERROR_MISSING_FASTA_FILES.tsv ]]; then
  hostname=`cat /proc/sys/kernel/hostname`
  declare -i len_check_fasta=`ls *.fasta 2> /dev/null | wc -l`
  echo "Started jParser and transChecker, please wait ..."
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
fi
rm -f check_filesize.txt
chmod -Rf 775 out_jParser/ out_tranChecker/ temp_autofix/ temp_svp/ Rfixed/
chmod -f 664 out_jParser/* out_tranChecker/* temp_autofix/* temp_svp/* Rfixed/* *.ann *.fasta all_jParser.txt all_tranChecker.txt jParser_transChecker.log sing_ddbj_mss_validation.log
chgrp -Rf mass-adm *
