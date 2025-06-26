#!/bin/bash
cd /data
# chmod -R 755 *
rm -rf out_jParser/ out_tranChecker/ temp_autofix/ temp_svp/ Rfixed/ all_jParser.txt all_tranChecker.txt
mkdir -p temp_svp temp_autofix Rfixed temp_svp/tmp temp_svp/temp_out
ls *.ann |rev | cut -c5- | rev > temp_svp/input_ids_ann.txt
ls *.fasta |rev | cut -c7- | rev > temp_svp/input_ids_fasta.txt
grep -Fxf temp_svp/input_ids_ann.txt temp_svp/input_ids_fasta.txt > temp_svp/input_ids.txt

nann=`cat temp_svp/input_ids_ann.txt | wc -l`
nfasta=`cat temp_svp/input_ids_fasta.txt | wc -l`
nids=`cat temp_svp/input_ids.txt | wc -l`
if [[ ${nids} -eq ${nann} && ${nids} -eq ${nfasta} ]]; then
  hostname=`cat /proc/sys/kernel/hostname`
  # export LC_CTYPE="en_US.utf8"
  # echo $hostname
  # cat temp_svp/input_ids.txt
  echo "Check and fixing blank spaces and tabulation on ANN file(s). New ANN file(s) are on Rfixed/"
  bash /mnt/formatlinux_remove-blankspaces_sing.sh
  
  ## mss_validation
  echo "Started to check qualifier values from ANN file(s) with DDBJ databases."
  echo "ddbj_mss_validation 2.91" > /data/Rfixed/sing_ddbj_validation.version

  rscript="/mnt/mss_validation_sing.R"
  nohup Rscript --vanilla ${rscript} > /data/Rfixed/mss_validation.log 2>&1 </dev/null &
  rscript_pid=$!
  echo "mss_validation pid: " $rscript_pid
  # Rscript ${rscript} 
  
  ## svp
  echo "Started to check FASTA file(s)."
  bash="/mnt/svp_sing.sh"
  nohup bash ${bash} > /data/Rfixed/svp.log 2>&1 </dev/null &
  bash_pid=$!
  echo "svp pid: " $bash_pid
  echo "Please wait, this step can take a few minutes depending on file size. Do not close this terminal."
  
  wait ${rscript_pid}
  wait ${bash_pid}
  
  # # run both mss_validation and svp 
  # nohup bash -c 'Rscript ${rscript} && bash ${bash}' > /data/Rfixed/mss_validation_svp.log
  
  rm -rf /data/temp_svp/temp_out /data/temp_svp/tmp
  
  # common_check
  echo "Checking COMMON part of ANN file(s)."
  bash2="/mnt/common_check_sing.sh" 
  nohup bash $bash2 >/data/Rfixed/common_check.log 2>&1 </dev/null
  bash2_pid=$!
  # bash $bash2 
  echo "common_check: " $bash2_pid
  #wait ${bash2_pid}
  
  if [[ -f /data/temp_svp/temp_warnings_SVP.tsv ]]; then
    if [[ -f /data/temp_svp/warnings_common_check.tsv ]]; then
      echo "cond1"
      cat /data/temp_svp/warnings_common_check.tsv /data/temp_svp/temp_warnings_SVP.tsv | sort | uniq > /data/Rfixed/warnings_SVP.tsv
    elif [[ ! -f /data/temp_svp/warnings_common_check.tsv ]]; then
      echo "cond2"
      cat /data/temp_svp/temp_warnings_SVP.tsv | sort | uniq > /data/Rfixed/warnings_SVP.tsv
    fi
  elif [[ ! -f /data/temp_svp/temp_warnings_SVP.tsv && -f /data/temp_svp/warnings_common_check.tsv ]]; then
    echo "cond3"
    cat /data/temp_svp/warnings_common_check.tsv | sort | uniq > /data/Rfixed/warnings_SVP.tsv
  fi
  if [[ -f /data/temp_autofix/warning_partial_overlap.b9 ]]; then
    echo "cond4"
    cat /data/temp_autofix/warning_partial_overlap.b9 >> /data/Rfixed/warnings_SVP.tsv
  fi
  
elif [[ ${nids} -lt ${nann} && ${nids} -eq ${nfasta} ]]; then
  echo "ERROR_MISSING_FASTA_FILES: check Rfixed/ERROR_MISSING_FASTA_FILES.tsv"
  grep -Fxvf temp_svp/input_ids.txt temp_svp/input_ids_ann.txt > Rfixed/ERROR_MISSING_FASTA_FILES.tsv
elif [[ ${nids} -eq ${nann} && ${nids} -lt ${nfasta} ]]; then
  echo "ERROR_MISSING_ANN_FILES: check Rfixed/ERROR_MISSING_ANN_FILES.tsv"
  grep -Fxvf temp_svp/input_ids.txt temp_svp/input_ids_fasta.txt > Rfixed/ERROR_MISSING_ANN_FILES.tsv
elif [[ ${nids} -lt ${nann} && ${nids} -lt ${nfasta} ]]; then
  echo "MULTIPLE PAIRS ARE MISSING, ANN AND FASTA FILES: check Rfixed/ERROR_MISSING_*_FILES.tsv"
  grep -Fxvf temp_svp/input_ids.txt temp_svp/input_ids_ann.txt > Rfixed/ERROR_MISSING_FASTA_FILES.tsv
  grep -Fxvf temp_svp/input_ids.txt temp_svp/input_ids_fasta.txt > Rfixed/ERROR_MISSING_ANN_FILES.tsv
fi
