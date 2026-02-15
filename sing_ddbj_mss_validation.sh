#!/bin/bash

BASE="/home/w3const/mssassist"
SIMG="sing-mssassist.sif"
BD="${PWD}:/data,${BASE}/tables:/srv,${BASE}/step1:/mnt"
LOGFILE="sing_ddbj_mss_validation.log"
[ -e ${LOGFILE} ] && rm -f ${LOGFILE} || touch ${LOGFILE}

# Substitute the file extension (.annt.tsv,.ann.txt, .seq.fa,.fa,.fna,.seq) with .ann/.fasta
echo "Checking file extensions and the existence of corresponding files." | tee -a ${LOGFILE}
echo "#No:    Basename" | tee -a ${LOGFILE}
ANNS=$(ls *{.ann,.annt.tsv,.ann.txt} 2>/dev/null)
SEQS=$(ls *{.fasta,.fa,.fna,.seq} 2>/dev/null) # .fa includes .seq.fa
[ -z "$ANNS" ] && [ -z "$SEQS" ] && echo "FMT0001: No Ann or Seq files found, the process is aborted." | tee -a ${LOGFILE} && exit 1
c=0
for v in ${ANNS}; do
  c=$((c+1))
  for extann in ".annt.tsv" ".ann.txt" ".ann"; do
    if [ "$v" != "${v%$extann}" ]; then
      basename="${v%$extann}"
      annfiles=($(ls "${basename}"{.annt.tsv,.ann.txt,.ann} 2>/dev/null))
      [ ${#annfiles[@]} -gt 1 ] && echo "FMT0002: More than one ANN files for '${basename}', aborted" | tee -a ${LOGFILE} && exit 1
      echo "#${c}: ${basename}" | tee -a ${LOGFILE}
      seqfiles=($(ls "${basename}"{.fasta,.seq.fa,.fa,.fna,.seq} 2>/dev/null))
      if [ ${#seqfiles[@]} -eq 1 ]; then
        seqf=${seqfiles[0]}
        if [ "$extann" != ".ann" ]; then
          mv -iv ${v} ${basename}.ann | tee -a ${LOGFILE}
        fi
        if [ "${seqf#${basename}}" != ".fasta" ]; then
          mv -iv ${seqf} ${basename}.fasta | tee -a ${LOGFILE}
        fi
        # ls ${basename}.ann ${basename}.fasta
      else
        echo "FMT0003: None or more than one SEQ file for '${basename}', abotted." | tee -a ${LOGFILE} && exit 1
      fi
      break
    fi
  done
done
echo "--------------------------------" | tee -a ${LOGFILE}
echo "Finished successfully" | tee -a ${LOGFILE}
echo "" | tee -a ${LOGFILE}
read -p "Press Y/y to continue or the other keys to stop: " yn
case ${yn} in 
  [yY] ) echo -n '' ;;
  * ) exit 0;; 
esac 


# nohup singularity run --bind .:/data,${BASE}/tables:/srv ${BASE}/ddbj_mss_validation_v2.91.sif </dev/null &>sing_ddbj_mss_validation.log &
# sing_ddbj_mss=$!
# echo "singularity PID: "${sing_ddbj_mss}
# wait ${sing_ddbj_mss}
echo "Running format_ann_file, mss_validation, SVP, and common_check."
singularity exec --bind ${BD} ${BASE}/${SIMG} /mnt/ddbj_mss_validation_sing.sh &>>${LOGFILE}

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
