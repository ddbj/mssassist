#!/bin/bash
###
# Developed by Andrea Ghelfi 2022.4.8
# Updated by Andrea Ghelfi 2025.4.11
# algorithm:
# update working list
# mv to DONE
# create file disable-upload /home/w3const/submissions/production/mass-id/disable-upload
# 
###
BASE="/home/w3const/mssassist"
SIMG="sing-mssassist.sif"
BD="$PWD:/workspace,${BASE}/.key:/tmp,${BASE}/step4:/src"
ACC_STORE="/home/w3const/work-kosuge/ACCNUM"
# 
rm -rf temp_py
mkdir -p temp_py temp_svp
echo "Updating New MSS working list"
mass_id=`pwd | rev | cut -f2 -d"/" | rev`
bash ${BASE}/ddbj_filetype.sh
if [[ -f temp_svp/filetype.tsv ]]; then
  cut -f 2 temp_svp/filetype.tsv | sort |uniq > temp_py/uniq_filetype.txt
fi
filetype=`cat temp_py/uniq_filetype.txt`
if [[ ${filetype} = "WGS" || ${filetype} = "TLS" || ${filetype} = "TPA-WGS" || ${filetype} = "TPA-TSA" || ${filetype} = "TSA" ]]; then
  prefix_count=`awk '$1~"MESSAGE" && $2== "Accession" {print $4"-"$6}' sakura_actual/*.report | uniq | wc -l`
  accession=`awk '$1~"MESSAGE" && $2== "Accession" {print $4"-"$6}' sakura_actual/*.report | uniq | awk '{gsub("$",",");printf $1}' | rev | cut -c2- | rev`
else
  acc_i=`cat sakura_actual/*.txt | cut -f2 | head -n1`
  acc_f=`cat sakura_actual/*.txt | cut -f2 | tail -n1`
  if [[ ${acc_i} = ${acc_f} ]]; then
    accession=${acc_i}
  else 
    accession=${acc_i}"-"${acc_f}
  fi
  prefix_count=`cat sakura_actual/acclist_dir/*.txt | cut -f2 | cut -c1,2 | sort | uniq | wc -l`
fi
div=`awk '$1=="LOCUS"{print $7; exit}' sakura_actual/*.FF`
bioproject=`awk -F"\t" '$4=="project"{print $5}' *.ann | sort | uniq | awk '{gsub("$",",");printf $1}'| rev | cut -c2- | rev`
biosample=`awk -F"\t" '$4=="biosample"{print $5}' *.ann | sort | uniq | awk '{gsub("$",",");printf $1}'| rev | cut -c2- | rev`
drr=`awk -F"\t" '$4=="sequence read archive"{print $5}' *.ann | sort | uniq | awk '{gsub("$",",");printf $1}'| rev | cut -c2- | rev`

printf "$mass_id%s\t$accession%s\t$prefix_count%s\t$div%s\t$bioproject%s\t$biosample%s\t$drr" > temp_py/line2add.tsv

# singularity run --cleanenv --containall --bind "$PWD":/workspace --bind ${BASE}/.key:/tmp ${BASE}/working.sif
singularity exec --bind ${BD} ${BASE}/${SIMG} /src/gsheet-working_list.py

echo "Data was uploaded to MSS working list"
chgrp -Rf mass-adm temp_py/
chmod -Rf 775 temp_py/
chmod -f 664 temp_py/* temp_svp/filetype.tsv *.ann *.fasta
# Copy accession number files to NSUB directory. 
[ -d ${ACC_STORE}/${mass_id} ] || ssh -i ~/.ssh/w3const/id_ed25519 w3const@a012 \
mkdir -p ${ACC_STORE}/${mass_id}
echo -e "cd ${ACC_STORE}/${mass_id}\nmput sakura_actual/acclist_dir/*.acclist.txt\nbye\n" | \
sftp -b - -i ~/.ssh/w3const/id_ed25519 w3const@a012
# 
cd ../..
mv $mass_id DONE/
echo "workdir was moved to DONE"
scp -i ~/.ssh/w3const/id_ed25519 ~/.ssh/w3const/disable-upload w3const@a012:/home/w3const/submissions/production/$mass_id/disable-upload
echo "File disable-upload was added to /home/w3const/submissions/production/"$mass_id
