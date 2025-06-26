#!/bin/bash
echo ${1}
awk -F"\t" -v OFS="\t" '{if($2 == "source") {entry = $1}; if($2 == "assembly_gap") {print entry, $3}}' ${1} | awk '{gsub("[.]", "\t");print $0}' > /data/temp_autofix/feature_assembly_gap.tsv;
awk -F"\t" -v OFS="\t" '{if($2 == "source") {entry = $1}; if($2 == "CDS") {print entry, $3}}' ${1} | awk '{gsub("complement", "complement "); gsub("join", ""); gsub("[(]", ""); gsub("[)]", ""); gsub(">", ""); gsub("<", ""); print $0}' | awk -F"\t" -v OFS="\t" '{gsub(",", "\n"$1"\t"); print $0}' | awk '{gsub("[.]", "\t");print $0}' > /data/temp_autofix/feature_cds.tsv;
