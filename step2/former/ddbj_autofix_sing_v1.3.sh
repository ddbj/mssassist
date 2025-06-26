#!/bin/bash

# version ddbj_autofix_v1.3 # includes remove function
# supercom or ddbjs1
confirmation_report=/data/Rfixed/confirmation_report.tsv
if test -f "$confirmation_report"; then
  hostname=`cat /proc/sys/kernel/hostname`
  rscript="/mnt/R_all_files2fix_20231206_sing.R"
  Rscript ${rscript}
  # test if there is file allfiles2fix.log
  if test -f "/data/temp_autofix/allfiles2fix.log"; then
      declare -i pos_common=`wc -l /data/temp_svp/common.txt | cut -f1 -d" "`
      declare -i test_files2fix=`wc -l /data/temp_autofix/allfiles2fix.log | cut -f1 -d" "`
      if [ $test_files2fix -gt 1 ]; then
          while IFS= read -r filename; do
            fgrep $filename /data/temp_autofix/allfiles2fix.log | cut -f 3,4,5,6 > /data/temp_autofix/temp_ann2fix.log
            awk -F"\t" -v OFS="\t" '$4 == "replace"{print $1,$2,$3}' /data/temp_autofix/temp_ann2fix.log > /data/temp_autofix/temp_ann_replace.log
            awk -F"\t" -v OFS="\t" '$4 == "add"{print $1,$2,$3}' /data/temp_autofix/temp_ann2fix.log > /data/temp_autofix/temp_ann_add.log
            awk -F"\t" -v OFS="\t" '$4 == "fix"{print $1,$2,$3}' /data/temp_autofix/temp_ann2fix.log > /data/temp_autofix/temp_ann_fix.log
            awk -F"\t" -v OFS="\t" '$4 == "remove"{print $1,$2,$3}' /data/temp_autofix/temp_ann2fix.log > /data/temp_autofix/temp_ann_remove.log
            declare -i len_replace=`wc -l /data/temp_autofix/temp_ann_replace.log | cut -f1 -d" "`
            declare -i len_add=`wc -l /data/temp_autofix/temp_ann_add.log | cut -f1 -d" "`
            declare -i len_fix=`wc -l /data/temp_autofix/temp_ann_fix.log | cut -f1 -d" "`
            declare -i len_remove=`wc -l /data/temp_autofix/temp_ann_remove.log | cut -f1 -d" "`
            if awk -F"\t" '$3 == "organism"' /data/temp_autofix/temp_ann_replace.log | grep -q 'organism'; then
              organism=$(awk -F"\t" '$3 == "organism"{print $1;exit}' /data/temp_autofix/temp_ann_replace.log)
              else
              organism=$(awk -F"\t" '$4 == "organism"{print $5;exit}' "$filename")
            fi
            #echo "Organism: "${organism}
            chmod -f 664 $filename
            if [ $len_replace -ge 1 ]; then
                awk -F"\t" -v OFS="%" '{print $3"\t"$2, $3"\t"$1}' /data/temp_autofix/temp_ann_replace.log > /data/temp_autofix/list_ann_replace.log
                declare -i qualf_rep=`wc -l /data/temp_autofix/list_ann_replace.log | cut -f 1 -d " "`
                for (( j=1; j<=$qualf_rep; j++ )); do
                  # echo "j: $j"
                  awk -v var1=$j 'NR==var1{print}' /data/temp_autofix/list_ann_replace.log > /data/temp_autofix/list_ann_replace_line.log
                  old=`cut -f1 -d "%" /data/temp_autofix/list_ann_replace_line.log`
                  new=`cut -f2 -d "%" /data/temp_autofix/list_ann_replace_line.log`
                  awk -v var_old="$old" -v var_new="$new" '{sub( var_old, var_new ); print}' ${filename} > ${filename}.temp
                  mv ${filename}.temp ${filename}
                done
            fi
            if [ $len_add -ge 1 ]; then
                awk -F"\t" -v OFS="\t" '{print $3, $1}' /data/temp_autofix/temp_ann_add.log > /data/temp_autofix/list_qualifiers.log
                readarray -t qualf < /data/temp_autofix/list_qualifiers.log
                for i in "${qualf[@]}"; do
                   # echo "i: $i"
                   awk -v qual_val="$i" -v var_org="$organism" -v var_qual="$qualifier" -v var_value="$value" '{gsub("organism\t" var_org, "organism\t" var_org "\n\t\t\t" qual_val); print}' $filename > $filename.temp
                   mv ${filename}.temp ${filename}
                done
            fi
            if [ $len_remove -ge 1 ]; then
                awk -F"\t" -v pos="$pos_common" '{ if (NR <= pos || $4 != "country") print }' ${filename} > ${filename}.temp
                mv ${filename}.temp ${filename}
            fi
            if [ $len_fix -eq 1 ]; then
              # autofix_overlap
              egrep $filename /data/Rfixed/feature_location.tsv > /data/temp_autofix/feature_location.tsv
              overlap="/mnt/autofix_overlap_sing_v0.6.R"
              Rscript ${overlap}
            fi
          done < /data/temp_autofix/allfilesnames2fix.log
      fi
  else
      echo "No errors/warnings were found, on annotation file, to be fixed."
  fi
  cd /data/Rfixed
  if [ -f warnings_SVP.tsv  ]; then
    declare -i len_svp0100=`egrep -c -m1 "SVP0100" warnings_SVP.tsv`
    if [ ${len_svp0100} -eq 1 ]; then
      rscript="/mnt/R_fix_svp_sing_v0.4.R"
      Rscript ${rscript}
    fi
  fi
  cd ../
  # Change permissions and group owner
  rm -f /data/Rfixed/input_ids*.txt /data/Rfixed/check_filesize.txt
  chmod -Rf 775 /data/Rfixed/out_jParser/ /data/Rfixed/out_tranChecker/
  chmod -f 664 /data/Rfixed/out_jParser/* /data/Rfixed/out_tranChecker/* /data/temp_autofix/* /data/temp_svp/* /data/Rfixed/*.ann /data/Rfixed/*.fasta /data/Rfixed/*.tsv /data/Rfixed/*.log
  if [ $hostname != "ddbjs1" ]; then
      chgrp -Rf mass-adm *
  fi
fi
#### END of function
