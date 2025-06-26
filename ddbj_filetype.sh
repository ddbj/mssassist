#!/bin/bash
# ddbj_file_type_v0.8
# 

mkdir -p temp_svp
rm -rf temp_svp/filetype.tsv
if test -d Rfixed ; then
  # echo "Rfixed"
  ls Rfixed/*.ann |rev | cut -c5- | rev > temp_svp/input_ids_ann2.txt
  ls Rfixed/*.fasta |rev | cut -c7- | rev > temp_svp/input_ids_fasta2.txt
  grep -Fxf temp_svp/input_ids_ann2.txt temp_svp/input_ids_fasta2.txt > temp_svp/input_ids2.txt
else
  # echo "no Rfixed"
  ls *.ann |rev | cut -c5- | rev > temp_svp/input_ids_ann2.txt
  ls *.fasta |rev | cut -c7- | rev > temp_svp/input_ids_fasta2.txt
  grep -Fxf temp_svp/input_ids_ann2.txt temp_svp/input_ids_fasta2.txt > temp_svp/input_ids2.txt
fi
declare -i test_input_ids=`wc -l temp_svp/input_ids2.txt | cut -f1 -d" "`
if [[ ${test_input_ids} -gt 0 ]]; then
  while IFS= read -r filename; do
    ann_ext=".ann"
    ann_filename="$filename$ann_ext"
    fasta_ext=".fasta"
    fasta_filename="$filename$fasta_ext"
    declare -i p1=`fgrep -n -m1 "source" $ann_filename | cut -f1 -d":"`
    head -n$p1 $ann_filename > temp_svp/common.txt
    datatype=`awk -F"\t" '$2=="DATATYPE"{print $5}' temp_svp/common.txt`
    declare -i len_datatype=`echo ${#datatype}`
    division=`awk -F"\t" '$2=="DIVISION"{print $5}' temp_svp/common.txt`
    declare -i len_division=`echo ${#division}`
    # keyword=`awk -F"\t" '$2=="KEYWORD"{print $5}' temp_svp/common.txt`
    dblink=`awk -F"\t" '$2=="DBLINK"{print $5}' temp_svp/common.txt`
    declare -i len_dblink=`echo ${#dblink}`
    topology=`awk -F"\t" '$2=="TOPOLOGY"{print $5}' temp_svp/common.txt`
    declare -i len_topology=`echo ${#topology}`
    if [[ ${len_datatype} -gt 0 ]]; then
      if [[ ${datatype} = "TLS" ]]; then
        filetype="TLS"
      elif [[ ${datatype} = "TPA-WGS" ]]; then
        filetype="TPA-WGS"
      elif [[ ${datatype} = "TPA-TSA" ]]; then
        filetype="TPA-TSA"
      elif [[ ${datatype} = "TPA" ]]; then
        declare -i len_keyword=`egrep "TPA:assembly" $ann_filename | wc -l `
        if [[ ${len_keyword} -eq 1 ]]; then
          filetype="TPA-assembly"
        fi
      elif [[ ${datatype} = "WGS" ]]; then
        if [[ ${division} = "ENV" ]]; then
          filetype="WGS"
        elif [[ ${division} != "CON" ]]; then
          filetype="WGS"
        fi
      else
        filetype="unknown"
      fi
    elif [[ ${len_datatype} -eq 0 ]]; then
      # tsa/complete genome
      if [[ $len_division -gt 0 ]]; then
        if [[ $division = "TSA" ]]; then
          filetype="TSA"
        elif [[ $division = "ENV" ]]; then
          if [[ $len_dblink -gt 0 && $len_topology -gt 0 ]]; then
            filetype="MAGs_CompleteGenome"
          elif [[ $len_dblink -eq 0 || $len_topology -eq 0 ]]; then
            filetype="ENV"
          else
            filetype="unknown"
          fi
        else
          filetype="unknown"
        fi
      elif [[ $len_division -eq 0 ]]; then

        # check entry length (fasta file), if > 50,000 complete_genome; else general
        #declare -i filelength=`awk '$0 !~ /^>/ { print length($0); exit }' ${fasta_filename}`# implemented on ddbj_mss_validation before fold -w80

        filelength=`cat temp_svp/filelength4sakura2DB.txt`


        if [[ ${filelength} -gt 1000000 ]]; then
          filetype="complete_genome"
        else
          filetype="general"
        fi
      else
        filetype="unknown"
      fi
    else
      filetype="unknown"
    fi
    echo ${filename}: ${filetype} ${filelength}
    printf "${ann_filename}%s\t${filetype}%s\n" >> temp_svp/filetype.tsv
  done < temp_svp/input_ids2.txt
fi
rm -rf temp_svp/input_ids_ann2.txt temp_svp/input_ids_fasta2.txt
