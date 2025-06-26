#!/bin/bash
############################################################################
# Developed by Andrea Ghelfi 
# Updated by Andrea Ghelfi 2025.3.20 (2025 new supercomputer settings)
# This script update tables required by ddbj_mss_validation and ddbj_autofix.
# 
############################################################################

USER=$(whoami)
rm -rf out_jParser out_tranChecker
mkdir -p out_jParser out_tranChecker
ls *.ann |rev | cut -c5- | rev > input_ids_ann.txt
ls *.fasta |rev | cut -c7- | rev > input_ids_fasta.txt
grep -Fxf input_ids_ann.txt input_ids_fasta.txt > input_ids.txt
while IFS= read -r filename; do
  ann_ext=".ann"
  ann_filename="$filename$ann_ext"
  fasta_ext=".fasta"
  fasta_filename="$filename$fasta_ext"
  fgrep -m1 "DATATYPE" $ann_filename | awk '{ gsub("\r", ""); gsub("  ", " "); gsub(" \t", "\t"); gsub("\t ", "\t"); gsub(" $", ""); gsub("\t$", ""); print $0 }' | cut -f 5 > check_wgs.txt
  declare -i check_wgs=`wc -l check_wgs.txt | cut -c1`
  if [ ${check_wgs} -gt 0 ]; then
    wgs=`head -n1 check_wgs.txt`
  else
    wgs="NA"
  fi
  ls -lh ${fasta_filename} | cut -f5 -d" " | awk '{sub ("G", ""); print}' | cut -f1 -d"." | awk '{if($1 ~ "M" || $1 ~ "K") print "1"; else print $0}' > check_filesize.txt
  declare -i check_filesize=`cat check_filesize.txt`
  if [ ${wgs} = "WGS" ] && [ ${check_filesize} -ge 10 ]; then
      jParser.sh -DWGS -x ${ann_filename} -s ${fasta_filename} -M 128g -e out_jParser/${filename}.txt
  elif [  ${wgs} = "WGS" ] && [ ${check_filesize} -lt 10 ]; then
      jParser.sh -DWGS -x ${ann_filename} -s ${fasta_filename} -e out_jParser/${filename}.txt
  else
      jParser.sh -x ${ann_filename} -s ${fasta_filename} -e out_jParser/${filename}.txt
  fi
  transChecker.sh -x ${ann_filename} -s ${fasta_filename} -e out_tranChecker/transl_error_${filename}.txt -o out_tranChecker/AA_seq_${filename}.faa
done < input_ids.txt
rm -f check_wgs.txt check_filesize.txt input_ids*
