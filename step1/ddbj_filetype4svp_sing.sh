#!/bin/bash

# common

if test -f /data/temp_svp/common2.txt; then
  datatype=`awk -F"\t" '$2=="DATATYPE"{print $5}' /data/temp_svp/common2.txt`
  len_datatype=`echo ${#datatype}`
  
  division=`awk -F"\t" '$2=="DIVISION"{print $5}' /data/temp_svp/common2.txt`
  len_division=`echo ${#division}`
  
  # keyword=`awk -F"\t" '$2=="KEYWORD"{print $5}' /data/temp_svp/common2.txt`
  dblink=`awk -F"\t" '$2=="DBLINK"{print $5}' /data/temp_svp/common2.txt`
  len_dblink=`echo ${#dblink}`
  topology=`awk -F"\t" '$2=="TOPOLOGY"{print $5}' /data/temp_svp/common2.txt`
  len_topology=`echo ${#topology}`
  if [ ${len_datatype} -gt 0 ]; then
    if [ ${datatype} = "TLS" ]; then
      filetype="TLS"
    elif [ ${datatype} = "TPA-WGS" ]; then
      filetype="TPA-WGS"
    elif [ ${datatype} = "TPA-TSA" ]; then
      filetype="TPA-TSA"
    elif [ ${datatype} = "TPA" ]; then
      len_keyword=`egrep "TPA:assembly" /data/temp_svp/common2.txt | wc -l `
      if [ ${len_keyword} -eq 1 ]; then
        filetype="TPA-assembly"
      fi
    elif [ ${datatype} = "WGS" ] && [ ${len_division} -eq 0 ]; then
      filetype="WGS"
    else
      filetype="unknown"
    fi
  elif [ ${len_datatype} -eq 0 ]; then
    # tsa/complete genome
    if [ $len_division -gt 0 ]; then
      if [ $division = "TSA" ]; then
        filetype="TSA"
      elif [ $division = "ENV" ]; then
        if [ $len_dblink -gt 0 ] && [ $len_topology -gt 0 ]; then
          filetype="MAGs_CompleteGenome"
        elif [ $len_dblink -eq 0 ] || [ $len_topology -eq 0 ]; then
          filetype="ENV"
        else
          filetype="unknown"
        fi
      else
        filetype="unknown"
      fi
    elif [ $len_division -eq 0 ]; then
      # check entry length (fasta file), if > 50,000 complete_genome; else general
       filelength=`cat temp_svp/filelength4sakura2DB.txt`
       echo ${filename}: ${filetype} ${filelength}
      if [ ${filelength} -gt 1000000 ]; then # Check with Okido-san if this value should be increased!
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
  printf "${filetype}%s\n" > /data/temp_svp/filetype4svp.tsv
fi
