#!/bin/bash

BASE="/home/w3const/mssassist"
SIMG="sing-mssassist.sif"
BD="${PWD}:/data,${BASE}/tables:/srv,${BASE}/step1:/mnt"
LOGFILE="sing_ddbj_mss_validation.log"
[ -e ${LOGFILE} ] && rm -f ${LOGFILE} || touch ${LOGFILE}
export LC_ALL=C

# Substitute the file extension (.annt.tsv,.ann.txt, .seq.fa,.fa,.fna,.seq) with .ann/.fasta
echo "- Changing file extension and checking the existence of corresponding files." | tee -a ${LOGFILE}
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
read -p "Press Y/y to continue, or any other key to stop: " yn
case ${yn} in
  [yY] ) echo '' ;;
  * ) exit 0;; 
esac 

# Detection of wrong file encodes
echo "- Checking file encodes" | tee -a ${LOGFILE}
cnterr=0
for v in *.ann; do
  chk1=$(file $v)
  chk2=$(file ${v%.ann}.fasta)
  if [[ "${chk1}" != "${v}: ASCII text"* ]]; then
    echo "FMT0004: ${v} Not ASCII text" | tee -a ${LOGFILE}
    cnterr=$((cnterr+1))
  fi
  if [[ "$chk2" != "${v%.ann}.fasta: ASCII text"* ]]; then
    echo "FMT0004: ${v%.ann}.fasta - Not ASCII text" | tee -a ${LOGFILE}
    cnterr=$((cnterr+1))
  fi
done
if [ $cnterr -gt 0 ]; then
  echo "Wrong file encodes detected, aborted." | tee -a ${LOGFILE}
  exit 1
else
  echo "Good, All files are ASCII text." | tee -a ${LOGFILE}
fi
cnterr=0
echo "" | tee -a ${LOGFILE}
read -p "Press Y/y to continue, or any other key to stop: " yn
case ${yn} in
  [yY] ) echo '' ;;
  * ) exit 0 ;;
esac

# Detecting lines exceeds 10,000 chars.
cnterr=0; c=0
echo "- Checking line in each ANN file exceeds 10,000 characters." | tee -a ${LOGFILE}
for v in *.ann; do
c=$((c+1))
# Change end-of-line code to LF if CR is detected
if grep -q $'\r' ${v}; then
  echo "${v} contains CR, changing line break code to LF" | tee -a ${LOGFILE}
  tr '\r' '\n' <${v} | sed '/^$/d' > ${v}.tmp && mv -f ${v}.tmp ${v}
  # nkf -Lu --overwrite ${v} ... Using nkf is not recommended because of slow speed against large file in size.
fi
if grep -q $'\r' ${v%.ann}.fasta; then
  echo "${v%.ann}.fasta contains CR, changing line break code to LF" | tee -a ${LOGFILE}
  tr '\r' '\n' <${v%.ann}.fasta | sed '/^$/d' > ${v%.ann}.fasta.tmp && mv -f ${v%.ann}.fasta.tmp ${v%.ann}.fasta
  # nkf -Lu --overwrite ${v%.ann}.fasta ... Using nkf is not recommended because of slow speed against large file in size.
fi
# Add LR if end of line does not have LR
if [ $(tail -c1 ${v} | od -An -c | sed 's/ \+//') != "\n" ]; then
  awk 1 ${v} > ${v}.tmp && mv -f ${v}.tmp ${v}
fi
if [ $(tail -c1 ${v%.ann}.fasta | od -An -c | sed 's/ \+//') != "\n" ]; then
  awk 1 ${v%.ann}.fasta > ${v%.ann}.fasta.tmp && mv -f ${v%.ann}.fasta.tmp ${v%.ann}.fasta
fi
# 
chk=$(cat $v | awk 'BEGIN {line=0} {++line; if (length($0) > 10000) print line":"length($0)} END {}')
if [ -n "$chk" ]; then
  ERRCODE="FMT0005"
  cnterr=$((cnterr+1))
  if [ $cnterr -eq 1 ]; then
      echo "# Error! The following line exceeds 10,000 characters." | tee -a ${LOGFILE}
      printf "ERRCODE\tNO\tFILENAME\tLINE\tLENGTH\n" | tee -a ${LOGFILE}
  fi
  for l in ${chk}; do
      printf "%s\t#%u\t%s\t%s\t%s\n" $ERRCODE $c $v ${l/:/ } | tee -a ${LOGFILE}
  done
fi
done
if [ $cnterr -eq 0 ]; then
  echo "Good! No line exceeds 10,000 characters." | tee -a ${LOGFILE}
  echo "" | tee -a ${LOGFILE}
  read -p "Press Y/y to continue, or any other key to stop: " yn
  case ${yn} in 
  [yY] ) echo -n '' ;;
  * ) exit 0;; 
  esac
else
  exit 1
fi
cnterr=0; c=0

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
