#!/bin/bash
  
while IFS= read -r filename; do
  echo "started file: "${filename}
  ann_ext=".ann"
  ann_filename="/data/Rfixed/${filename}${ann_ext}"
  fasta_ext=".fasta"
  fasta_filename="${filename}${fasta_ext}"
  # only common (ann header)
  p1=`egrep -n -m1 "source" ${ann_filename} | cut -f1 -d":"`
  echo "line where source is: "${p1}
  if [ ${p1} -gt 1 ]; then
  # common
  head -n${p1} ${ann_filename} > /data/temp_svp/common2.txt
  # check organelle/organism
  awk -F"\t" -v OFS="\t" -v var1="${p1}" 'NR >= var1 && NR < var1+8 && $4 == "organelle" {print $4; exit}' ${ann_filename} > /data/temp_svp/qualifier_organelle.txt
  
  # fasta
  # implement two cpp functions
  echo ${filename} > /data/temp_svp/input2cpp.txt
  /mnt/oneline_fasta
  /mnt/exp_split
  
  awk -F"\t" 'NR==1{ print $2; exit }' /data/temp_svp/temp_length_firstlastbases.txt > /data/temp_svp/filelength4sakura2DB.txt
  # ! awk '{if(NR==1) {print $0} else {if($0 ~ /^>/) {print "\n" $0} else {printf $0}}}' $fasta_filename | awk '{gsub("/","");print}' > /data/temp_svp/oneline.fasta
  # ! fgrep -r ">" /data/temp_svp/oneline.fasta | awk '{sub(">",""); print $1}' > /data/temp_svp/temp_entry_ids.tsv
  
  # what if there are no biosample_id? (see below, for TSA data)
  # add locus_tag; only CDS on annotated WGS have locus_tag
  awk -F"\t" -v OFS="\t" '{if($4 == "biosample"){biosample = $5}; if($2 == "source"){entry = $1}; if($2 == "assembly_gap"){feature = $2; location = $3}; if($4 == "gap_type"){gap_type = $5}; if($4 == "estimated_length"){estimated_length = $5}; if($4 == "linkage_evidence") {print biosample, entry, location, gap_type, $5, estimated_length, feature}}' $ann_filename > /data/temp_svp/temp_main_table.txt
  biosample_id=`awk -F"\t" 'NR==1{print $1}' /data/temp_svp/temp_main_table.txt`
  # Proposal 7: Show warnings when the nucleotide sequence starts or ends with N. ! change this algorithm!
  #  ! egrep -v ">" /data/temp_svp/oneline.fasta | awk '{print length($0)}' > /data/temp_svp/temp_length.txt
  #  ! egrep -v ">" /data/temp_svp/oneline.fasta | cut -c1 > /data/temp_svp/temp_firstbase.txt
  #  ! egrep -v ">" /data/temp_svp/oneline.fasta | awk '{print substr($0,length($0),1)}' > /data/temp_svp/temp_lastbase.txt
  #  ! paste /data/temp_svp/temp_entry_ids.tsv /data/temp_svp/temp_length.txt /data/temp_svp/temp_firstbase.txt /data/temp_svp/temp_lastbase.txt > /data/temp_svp/temp_length_firstlastbases.txt
  awk -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '$3 == "N" || $3 == "n" {print var2, "warning", "SVP0070", var1, $1 }' /data/temp_svp/temp_length_firstlastbases.txt > /data/temp_svp/warning_seq_start_with_N.b9
  awk -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '$4 == "N" || $4 == "n" {print var2, "warning", "SVP0071", var1, $1 }' /data/temp_svp/temp_length_firstlastbases.txt > /data/temp_svp/warning_seq_end_with_N.b9
  # Proposal 5: When multiple types of unknown gap length are used in the annotation, we should detect them with the gap_type & evidence
  # add exact number!
  awk -F"\t" -v OFS="\t" '$6 == "unknown" {print $3,$1,$2}' /data/temp_svp/temp_main_table.txt | awk -F"[.]" -v OFS="\t" '{print $1, $3, $3-$1+1 }' > /data/temp_svp/temp_unknown_assembly_gap.txt
  cut -f3,5 /data/temp_svp/temp_unknown_assembly_gap.txt |sort|uniq > /data/temp_svp/temp_number_unknown_assembly_gap.txt
  lines_unknown=`wc -l /data/temp_svp/temp_number_unknown_assembly_gap.txt | cut -f1 -d" "`
  if [ ${lines_unknown} -gt 1 ]; then
    awk -v var3="${lines_unknown}" -v var2="${ann_filename}" -v OFS="\t" 'END{print var2, "warning", "SVP0050", $1, "Multiple unknown gaps: " var3 }' /data/temp_svp/temp_number_unknown_assembly_gap.txt > /data/temp_svp/warning_number_unknown_assembly_gap.b9
  fi
  # Proposal 4: Show warnings when the unknown gap length exceeds 1000-bp.
  awk -F"\t" -v var2="${ann_filename}" -v OFS="\t" '$5 > 1000 {print var2, "warning", "SVP0040", $3, "Unknown gap length: " $5 "-bp" , $1".."$2 }' /data/temp_svp/temp_unknown_assembly_gap.txt > /data/temp_svp/warning_length_unknown_gap_length.b9
  # Proposal 6  Show warnings if all known assembly_gap have the same length
  awk -F"\t" -v OFS="\t" '$6 == "known" {print $3,$1,$2}' /data/temp_svp/temp_main_table.txt | awk -F"[.]" -v OFS="\t" '{print $1"\t"$3, $3-$1+1 }' > /data/temp_svp/temp_known_assembly_gap.txt
  cut -f3,5 /data/temp_svp/temp_known_assembly_gap.txt |sort|uniq > /data/temp_svp/temp_number_known_assembly_gap.txt
  lines_known=`wc -l /data/temp_svp/temp_number_known_assembly_gap.txt | cut -f1 -d" "`
  # considering only if there are more than one entry
  if [ $lines_known -eq 1 ]; then
    awk -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "SVP0060", $1 }' /data/temp_svp/temp_number_known_assembly_gap.txt > /data/temp_svp/warning_number_known_assembly_gap.b9
  fi
  # Proposal 8: Check the consistency between gap_type and linkage_evidence (https://www.ddbj.nig.ac.jp/ddbj/qualifiers-e.html)
  awk -F"\t" -v var2="$ann_filename" -v OFS="\t" '$4=="between scaffolds" || $4=="telomere" || $4=="centromere" || $4=="short arm" || $4=="heterochromatin" || $4=="repeat between scaffolds" || $4=="unknown" {print var2, "warning", "SVP0080", $1, "gap_type (" $4 ") does not require linkage_evidence (" $5 ")" , $3}' /data/temp_svp/temp_main_table.txt > /data/temp_svp/warning_consistence_gapType_linkageEvidence.b9
  awk -F"\t" -v var2="$ann_filename" -v OFS="\t" '$4=="contamination" && $5 != "unspecified" {print var2, "warning", "SVP0081", $1, "gap_type ("$4 ") requires linkage_evidence = unspecified, but the actual value is: " $5, $3}' /data/temp_svp/temp_main_table.txt > /data/temp_svp/warning_gapType_contamination.b9
  # Proposal 2. If gap regions exceeds threshold for each entry, show warnings
  awk -F"\t" -v OFS="." '{print $3,$2}' /data/temp_svp/temp_main_table.txt | awk -F"[.]" -v OFS="\t" '{print $4, $3-$1+1}' > /data/temp_svp/temp_partial_total_length_assembly_gap_per_entry.txt
  cut -f2 /data/temp_svp/temp_partial_total_length_assembly_gap_per_entry.txt | sort | uniq | wc -l | cut -f1 -d" " > /data/temp_svp/temp_len_unique_partial_total_length_assembly_gap.txt
  wc -l /data/temp_svp/temp_partial_total_length_assembly_gap_per_entry.txt | cut -f1 -d" " > /data/temp_svp/temp_len_partial_total_length_assembly_gap.txt
  # create a variable from file
  unique=`cat /data/temp_svp/temp_len_unique_partial_total_length_assembly_gap.txt`
  total=`cat /data/temp_svp/temp_len_partial_total_length_assembly_gap.txt`
  if [ $unique != $total ]; then
    # if there are more than one gap per entry:
    awk -v OFS="\t" '{ k = $1}{ sum[k] += $2; count[k]++ }END{ for (i in sum) if (count[i] >= 1) print i, sum[i] }' /data/temp_svp/temp_partial_total_length_assembly_gap_per_entry.txt > /data/temp_svp/temp_total_length_assembly_gap_per_entry.txt
    awk 'FNR==NR{a[$1]=$2;next} ($1 in a) {print $1,a[$1],$2, (a[$1]/$2)*100}' /data/temp_svp/temp_total_length_assembly_gap_per_entry.txt /data/temp_svp/temp_length_firstlastbases.txt > /data/temp_svp/temp_fraction_gaps.txt
  else
    # merge two files by common field
    awk 'FNR==NR{a[$1]=$2;next} ($1 in a) {print $1,a[$1],$2, (a[$1]/$2)*100}' /data/temp_svp/temp_partial_total_length_assembly_gap_per_entry.txt /data/temp_svp/temp_length_firstlastbases.txt > /data/temp_svp/temp_fraction_gaps.txt
  fi
  FILE=/data/temp_svp/temp_fraction_gaps.txt
  if test -f "$FILE"; then
    awk -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '$4 > 50 {print var2, "warning", "SVP0020", var1, $1 ,"Gaps exceeds " $4 "% of total entry length" }' /data/temp_svp/temp_fraction_gaps.txt > /data/temp_svp/warning_gap_regions_exceed_50perc.b9
  fi
  # Proposal 2b. {Nucleotide residues excluding (a/c/g/t)} in SequenceFile / sequence length > 0.5 # optimize this algorithm
  end_file="//"
  # ! fgrep -v ">" /data/temp_svp/oneline.fasta | awk -v OFS="\t" 'BEGIN{IGNORECASE=1;}{total = length ($0)} {print gsub(/N/,"")/total}' > /data/temp_svp/temp_perc_Ns.tsv
  # ! awk -v OFS="\t" 'BEGIN{IGNORECASE=1;}{total = length ($0)} {print gsub(/N/,"")/total}' /data/temp_svp/oneline.txt > /data/temp_svp/temp_perc_Ns.tsv
  # ! paste /data/temp_svp/temp_entry_ids.tsv /data/temp_svp/temp_perc_Ns.tsv > /data/temp_svp/temp_entry_perc_Ns.tsv
  awk -F"%" -v OFS="\t" 'BEGIN{IGNORECASE=1;}{total = length ($2)} {print $1, gsub(/N/,"")/total}' /data/temp_svp/oneline.txt > /data/temp_svp/temp_entry_perc_Ns.tsv
  awk -F "\t" -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '$2 > 0.5{sub(">", ""); print var2, "warning", "SVP0022", var1, $1 ,"The amount of 'Ns' exceeds " $2*100 "% of the total amount of bases"}' /data/temp_svp/temp_entry_perc_Ns.tsv > /data/temp_svp/warning_perc_of_Ns_exceed_50perc.b9
  # format fasta file in three lines ending with //. Add line and pattern '//' before >; remove first line (//); then add // in the last line
  awk '{ sub(/%/,"\n"); gsub(/>/,"//\n>"); print }' /data/temp_svp/oneline.txt | tail -n+2 | fold -w80 > /data/Rfixed/${fasta_filename}

  echo $end_file >> /data/Rfixed/$fasta_filename
  # SVP0100: Modify the location of rRNA features output from DFAST.
  awk -F"\t" -v OFS="\t" '{if($4 == "biosample"){biosample = $5}; if($2 == "source"){entry = $1}; if($2 == "rRNA"){location = $3}; if($5 ~ "aligned only") {print biosample, entry, location, $5}}' $ann_filename > /data/temp_svp/temp_partial_rrna.txt
  awk '!/..>/ && !/</' /data/temp_svp/temp_partial_rrna.txt | awk -F "\t" -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "SVP0100", var1, $2 ", partial rRNA", $3 }' > /data/temp_svp/warning_partial_rrna.b9
  # SVP0110: function intron_length less than 11 bases (added locus_tag: from v0.6); removing rule SVP0110
  awk -F"\t" -v OFS=";" '{if($2 == "source"){entry = $1}; if($2 == "CDS" || $2 == "mRNA") {print entry, $2, $4, $5, $3}}' $ann_filename > /data/temp_svp/temp_join1.txt # check potential bug on feature line!
  
  # fixed bug on $3 = "locus_tag" on file 'temp_join1.txt' 
  fgrep "join" /data/temp_svp/temp_join1.txt | awk '{gsub("join",""); gsub("complement",""); gsub("[(]",""); gsub("[)]",""); gsub("<",""); gsub(">",""); gsub("[.]","%"); print $0}' > /data/temp_svp/temp_join2.txt
  
  awk -F";" '{gsub("%%", "\n"$1";"$2";"$3";"$4";"); print}' /data/temp_svp/temp_join2.txt | fgrep "," > /data/temp_svp/join2.txt
  awk '{gsub(";",","); print}' /data/temp_svp/join2.txt | awk -F"," -v OFS="\t" '{print $1, $2, $3, $4, $5","$6, ($6-1)-($5+1)+1}' | awk -F"\t" -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '$6 < 11 {print var2, "warning", "SVP0110", var1, $1, $2, $3, $4, $5, "intron length = " $6}' > /data/temp_svp/warning_intron_length2.b9
  awk -F "\t" -v OFS=";" '{print $8, $0}' /data/temp_svp/warning_intron_length2.b9 > /data/temp_svp/temp_intron_length2.txt
  awk -F "\t" '{print $8}' /data/temp_svp/warning_intron_length2.b9 > /data/temp_svp/temp_intron_length_locus_tag.txt
  # SVP0141: Detect artificial_location. Warning intron_len < 11 bases and artificial_location qualifier.
  awk -F"\t" '{if($4 == "locus_tag"){locus_tag = $5}; if($4 == "artificial_location" ) {print locus_tag}}' $ann_filename > /data/temp_svp/temp_artificial_location.txt
  awk -F";" 'FNR==NR{a[$1]=$1;next} ($1 in a) {print $2}' /data/temp_svp/temp_artificial_location.txt /data/temp_svp/temp_intron_length2.txt | awk '{sub("SVP0110", "SVP0141"); print $0 }' > /data/temp_svp/warning_artificial_location.b9
  # SVP0140: Detect artificial_location. Warning intron_len < 11 bases and NO artificial_location qualifier.# row below was fixed
  grep -Fxvf /data/temp_svp/temp_artificial_location.txt /data/temp_svp/temp_intron_length_locus_tag.txt > /data/temp_svp/temp_no_artificial_location.txt
  awk -F";" 'FNR==NR{a[$1]=$1;next} ($1 in a) {print $2}' /data/temp_svp/temp_no_artificial_location.txt /data/temp_svp/temp_intron_length2.txt | awk '{sub("SVP0110", "SVP0140"); print $0 }' > /data/temp_svp/warning_no_artificial_location.b9
  # SVP0130: Check full length of an entry. Unacceptable sequences shorter than 100 bases.
  awk -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '$2 < 100 || $3 == "n" {print var2, "warning", "SVP0130", var1, $1 }' /data/temp_svp/temp_length_firstlastbases.txt > /data/temp_svp/warning_length_100nucl.b9
  # SVP150: multiple locus_tag (/sit-147-0002/20211124: CDS and mRNA, same locus_tag)
  awk -F"\t" -v OFS="\t" '{if($4 == "locus_tag") {print $5}}' $ann_filename | awk 'a[$1]++{print $1}' > /data/temp_svp/temp_multi_locus_tag.txt
  awk -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "SVP0150", var1, $1 }' /data/temp_svp/temp_multi_locus_tag.txt > /data/temp_svp/warning_multi_locus_tag.b9
  # Implement rule CMC0110: synonym
  # RNA Editing check (for organelle; attention: DBLINK is not mandatory); check svp_rna_editing_v0.1.sh
  # merge all warning files
  cat /data/temp_svp/warning_*.b9 >> /data/temp_svp/temp_warnings_SVP.tsv
  # SVP0400 Added NR for TRAD-260 check_cds_partial_location
  echo "started ddbj_filetype"
  sh /mnt/ddbj_filetype4svp_sing_v0.2.sh
  echo "finished ddbj_filetype"
  len_filetype=`wc -l /data/temp_svp/filetype4svp.tsv | cut -f1 -d" "`
  echo "len_filetype4svp: "$len_filetype
  if [ ${len_filetype} -eq 1 ]; then
    filetype=`cut -f1 /data/temp_svp/filetype4svp.tsv`
    echo "filetype4svp: "$filetype
    if [ ${filetype} = "TSA" ]; then
      echo "started SVP0300: "${ann_filename}
      awk -F"\t" -v OFS="\t" -v var2="$ann_filename" '$3 ~ "complement" {print var2, "warning", "SVP0300", $2, $3, "line="NR}' ${ann_filename} > /data/temp_svp/warning_tsa_warning_complement.b9
      cat /data/temp_svp/warning_tsa_warning_complement.b9 >> /data/temp_svp/temp_warnings_SVP.tsv
      echo "finished SVP0300: "${ann_filename}
      #
      echo "started SVP0400: "${ann_filename} # v2023.01.18(NSUB000283)
      awk -F"\t" -v OFS=";" '{if($2 == "source"){entry = $1}; if($2 == "CDS" || $2 == "mRNA"){feature = $2; location=$3; pos_loc=NR}; if($4 == "codon_start") {print entry, feature, $4, $5,NR, location, pos_loc}}' ${ann_filename} > /data/temp_svp/temp_join1_nr.txt
      Rscript --vanilla /mnt/cds_partial_location_v0.3.R ${ann_filename}
      echo "finished SVP0400: "${ann_filename}
    fi
    # rule_gtag
    if [ ${filetype} != "TLS" ] && [ ${filetype} != "TSA" ] && [ ${filetype} != "TPA-TSA" ] && [ ${filetype} != "TPA-assembly" ]; then
      if test -f "/data/temp_svp/qualifier_organelle.txt"; then
         len_organelle=`wc -l /data/temp_svp/qualifier_organelle.txt | cut -f1 -d" "`
         if [ ${len_organelle} -eq 0 ]; then
            echo "started rule_gtag: "${ann_filename}
            # intron positions CDS and mRNA (check both and remove redundancy searches ... !)
            awk -F"\t" -v OFS=";" '{if($2 == "source"){entry = $1}; if(($2 == "CDS" || $2 == "mRNA") && ($3 ~ "join")) {print entry,NR, $2, $3}}' ${ann_filename} > /data/temp_svp/temp_gt_ag_rule.txt
            if test -f "/data/temp_svp/temp_gt_ag_rule.txt"; then
              len_gt_ag_rule=`wc -l /data/temp_svp/temp_gt_ag_rule.txt | cut -f1 -d" "`
              if [ ${len_gt_ag_rule} -gt 0 ]; then
                # reverse (complement)
                egrep "complement" /data/temp_svp/temp_gt_ag_rule.txt > /data/temp_svp/temp_gt_ag_rule_join_compl.txt
                awk -F"join" -v OFS="\t" '{gsub("[.]", "\n"$1); print $0}' /data/temp_svp/temp_gt_ag_rule_join_compl.txt | awk -F";" '$4 ~ "," {sub(",",";");sub("complement[(]",""); print $0}' > /data/temp_svp/temp_gt_ag_rule_join_mRNA_introns_compl.txt
                # forward
                egrep -v "complement" /data/temp_svp/temp_gt_ag_rule.txt > /data/temp_svp/temp_gt_ag_rule_join.txt
                awk -F"join" -v OFS="\t" '{gsub("[.]", "\n"$1); print $0}' /data/temp_svp/temp_gt_ag_rule_join.txt | awk -F";" '$4 ~ "," {sub(",",";"); print $0}' > /data/temp_svp/temp_gt_ag_rule_join_mRNA_introns.txt
                Rscript --vanilla /mnt/rule_gtag_sing_v2.5.R
                cat /data/temp_svp/temp_out/error_trad359_* > /data/temp_svp/temp_error_rule_gtag.txt
                # calculate percentage of error rule_gtag
                declare -i total=`cat /data/temp_svp/total_number_introns.txt`
                declare -i err=`wc -l /data/temp_svp/temp_error_rule_gtag.txt | cut -f1 -d" "`
                echo | awk -v var1=${total} -v var2=${err} '{print int((var2/var1)*100)}' > /data/temp_svp/number_perc_rule_gtag.txt
                declare -i number_perc_rule_gtag=`echo | awk -v var1=${total} -v var2=${err} '{print int((var2/var1)*100)}'`
                if [ ${number_perc_rule_gtag} -gt 5 ]; then
                  awk -F"\t" -v OFS="\t" -v var2="$ann_filename" '{print var2, "error", "SVP0500", "GT-AG rule fails in " $1 " % of total introns. Check file Rfixed/error_rule_gtag.tsv"}' /data/temp_svp/number_perc_rule_gtag.txt > /data/temp_svp/error_rule_gtag_5perc.b9
                  cat /data/temp_svp/error_rule_gtag_5perc.b9 >> /data/temp_svp/temp_warnings_SVP.tsv
                elif [ ${number_perc_rule_gtag} -le 5 ]; then
                  awk -F"\t" -v OFS="\t" -v var2="$ann_filename" '{print var2, "warning", "SVP0510", "GT-AG rule fails in " $1 " % of total introns. Check file Rfixed/error_rule_gtag.tsv"}' /data/temp_svp/number_perc_rule_gtag.txt > /data/temp_svp/warning_rule_gtag_5perc.b9
                  cat /data/temp_svp/warning_rule_gtag_5perc.b9 >> /data/temp_svp/temp_warnings_SVP.tsv
                fi
                awk -v OFS="\t" -v var1=${ann_filename} '{ print var1, $0 }' /data/temp_svp/temp_error_rule_gtag.txt >> /data/Rfixed/error_rule_gtag.tsv
                # rm -rf /data/temp_svp/temp_error_rule_gtag.txt
              fi
            fi
         fi
      fi
    fi
  fi
else
  echo "$filename: Missing feature source."
fi
echo "finish file: "${ann_filename}
done < /data/temp_svp/input_ids.txt
if test -f /data/temp_svp/temp_cds_partial_location_error.tsv; then
  printf "filename%s\tentry%s\tfeature%s\tcodon_start_value%s\ttadashi_codon_start_value%s\tlocation%s\ttadashi_location%s\tlength%s\n" > /data/temp_svp/cds_colnames.tsv
  cat /data/temp_svp/cds_colnames.tsv /data/temp_svp/temp_cds_partial_location_error.tsv > /data/Rfixed/curators_cds_partial_location_error.tsv
fi
echo "finish loop input_ids"




