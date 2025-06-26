#!/bin/bash

BASE="/home/w3const/mssassist"
LOGFILE="${BASE}/tables/update_taxonomy.log"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOGFILE" 2>&1
}

log "Updating taxonomy data started"

mkdir -p -m 775 ${BASE}/tables/taxonomy
cd ${BASE}/tables/taxonomy
cp /lustre9/open/database/ddbjshare/private/ftp-private.ncbi.nih.gov/ncbi_taxonomy/taxonomydb/taxdump.tar.gz .
current_date=$(date +%Y-%m-%d)
extracted_date=$(ls -l --time-style=full-iso taxdump.tar.gz |cut -f6 -d" " )
file_size=$(echo "$(stat -c%s taxdump.tar.gz) / 1024 / 1024" | bc)

if [[ "$extracted_date" = "$current_date" && "$file_size" -gt 200 ]]; then
    log "Extracting taxdump ..."
    tar xvzf taxdump.tar.gz
    awk '{gsub("\t","");print}' names.dmp | awk -F"|" -v OFS="|" '$4=="scientific name"{print $1, $2}' > taxid2scientific_name.tsv
    tail -n+2 taxid2scientific_name.tsv | cut -f2 -d"|" > clean_taxid2scientific_name.tsv
    # virus-phage
    awk -F"|" '$3 ~ "Viruses;" {gsub("\t", "");print $2}' fullnamelineage.dmp > viroses.list
    awk -F"|" '/phage/ && !/cellular organisms/ && !/Viruses;/ {gsub("\t", ""); print $2}' fullnamelineage.dmp > phage.list
    cat viroses.list phage.list > virus_phage.list
    # copy to destination
    file_size2=$(echo "$(stat -c%s virus_phage.list) / 1024 / 1024" | bc)
    if [[ "$file_size2" -ge 9 ]]; then
        log "Copying ..."
        cp clean_taxid2scientific_name.tsv virus_phage.list ../
    else
        log "File virus_phage.list is corrupted and was not be copied."
    fi
else {
    log "File taxdump not updated or corrupted."
}  
fi
