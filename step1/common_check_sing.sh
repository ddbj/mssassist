#!/bin/bash
while IFS= read -r filename; do
  ann_ext=".ann"
  ann_filename="/data/Rfixed/${filename}${ann_ext}"
  fasta_ext=".fasta"
  fasta_filename="/data/Rfixed/${filename}${fasta_ext}"
  # only common (ann header)
  p1=`grep -n -m1 -P "\tsource\t" $ann_filename | cut -f1 -d":"`
  if [ $p1 -gt 1 ]; then
    ## common
    head -n$p1 $ann_filename > /data/temp_svp/common.txt
    if test -f /data/temp_svp/common.txt; then
      biosample_id=`awk -F"\t" '$4=="biosample"{print $5}' /data/temp_svp/common.txt`
      # length ${#biosample_id}
      #  len_biosample_id=`awk -F"\t" '$4=="biosample"{print $5}' /data/temp_svp/common.txt | wc -l`
      if [ ${#biosample_id} -gt 10 ]; then
        # echo ${#biosample_id}
        # CMC0100: check organism on tax dump file
        taxdump="/srv/clean_taxid2scientific_name.tsv"
        echo ${ann_filename} > /data/temp_svp/temp_ann_filename.temp
        awk -F"\t" '$4=="organism" {print $5}' ${ann_filename} | sort | uniq > /data/temp_svp/organism_ann.txt
        len_organism_ann=`wc -l /data/temp_svp/organism_ann.txt | cut -f1 -d" "`
        # implement fuzzy search
        if [ ${len_organism_ann} -gt 0 ] ; then
          # echo "start Rfuzzy"
          Rscript --vanilla /mnt/Rfuzzy_search_taxdump_sing.R
          # echo "end Rfuzzy"
        fi
        if [ -f /data/temp_svp/temp_organism_warning_org_taxdump.txt ] ; then
          len_wrong_organism_ann=`wc -l /data/temp_svp/temp_organism_warning_org_taxdump.txt | cut -f1 -d" "`
          if [ ${len_wrong_organism_ann} -gt 0 ] ; then
            awk -F"\t" -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "CMC0100", var1, "taxdump hint="$2, "ann_file="$3 }' /data/temp_svp/temp_organism_warning_org_taxdump.txt > /data/temp_svp/organism_warning_org_taxdump.b11
          fi
        fi
        # CMC0020 contact; CMC0021 email
        contact_dir="/srv/biosample.summary_contact.csv"
        fgrep $biosample_id ${contact_dir} > /data/temp_svp/temp_contact_email.txt
        contact_ann=`awk -F"\t" '$4=="contact"{print $5}' /data/temp_svp/common.txt`
        email_ann=`awk -F"\t" '$4=="email"{print $5}' /data/temp_svp/common.txt`
        if test -f /data/temp_svp/temp_contact_email.txt ; then
          # CMC0023, CMC0024, CMC0022 ab_name; test if duplicated ab_name; ab_name from submitter feature (not reference)
          if (grep -Pq "\tSUBMITTER\t" /data/temp_svp/common.txt);then
            psubmi=`grep -P -n -m1 "\tSUBMITTER\t" /data/temp_svp/common.txt | cut -f1 -d":"`
          else
            psubmi=0
          fi
          if (grep -Pq "\tstreet\t" /data/temp_svp/common.txt);then
            psubmf=`grep -P -n -m1 "\tstreet\t" /data/temp_svp/common.txt | cut -f1 -d":"`
          else
            psubmf=0
          fi

          if [ ${psubmi} -gt 0 ]  && [ ${psubmf} -gt 0 ]; then
            # echo "$filename" >> /data/temp_svp/00.log
            awk -v var1="$psubmi" -v var2="$psubmf" '(NR>=var1 && NR<=var2){ print $0 }' /data/temp_svp/common.txt > /data/temp_svp/temp_submitter_info.txt
            if test -f /data/temp_svp/temp_submitter_info.txt ; then
              egrep "ab_name" /data/temp_svp/temp_submitter_info.txt | cut -f5 | sort |uniq > /data/temp_svp/temp_abname_ann.txt
              len_ab_name=`egrep "ab_name" /data/temp_svp/temp_submitter_info.txt | wc -l`
              len_ab_name_uniq=`egrep "ab_name" /data/temp_svp/temp_submitter_info.txt | cut -f5 | sort |uniq | wc -l`
              if [ ${len_ab_name} -gt ${len_ab_name_uniq} ]; then
                awk -F"|" -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "CMC0023", $1 }' /data/temp_svp/temp_contact_email.txt > /data/temp_svp/common_warning_duplicated_submitter_abname.b9
              fi
            fi
          elif [ ${psubmi} -gt 0 ] && [ ${psubmf} -eq 0 ]; then
            # echo "$filename" >> /data/temp_svp/01.log
            # printf "warning\tCMC0024\t%s\t%s\n" $ann_filename $biosample_id  > /data/temp_svp/common_warning_missing_street.b9
            printf "%s\twarning\tCMC0024(no street)\t\n" $ann_filename > /data/temp_svp/common_warning_missing_street.b9
          fi
          # CMC0025: check duplicated ab_name on Reference feature
          referencei=`egrep -n -m1 "REFERENCE" $ann_filename | cut -f1 -d":"`
          referencef=`egrep -n -m1 "year" $ann_filename | cut -f1 -d":"`
          if [ ${referencei} -gt 0 ] && [ ${referencef} -gt 0 ]; then
            awk -v var1="$referencei" -v var2="$referencef" '(NR>=var1 && NR<=var2){ print $0 }' $ann_filename > /data/temp_svp/temp_reference_info.txt
            if test -f /data/temp_svp/temp_reference_info.txt ; then
              #egrep "ab_name" /data/temp_svp/temp_reference_info.txt | cut -f5 | sort |uniq > /data/temp_svp/temp_abname_ref_ann.txt
              len_ab_name_ref=`egrep "ab_name" /data/temp_svp/temp_reference_info.txt | wc -l`
              len_ab_name_ref_uniq=`egrep "ab_name" /data/temp_svp/temp_reference_info.txt | cut -f5 | sort |uniq | wc -l`
              if [ ${len_ab_name_ref} -gt ${len_ab_name_ref_uniq} ]; then
                awk -F"|" -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "CMC0025", $1 }' /data/temp_svp/temp_contact_email.txt > /data/temp_svp/common_warning_duplicated_reference_abname.b9
              fi
            fi
          elif [ ${referencei} -gt 0 ] && [ ${referencef} -eq 0 ]; then
            printf "$ann_filename%s\twarning%s\tCMC0026%s\t$biosample_id%s\n" > /data/temp_svp/common_warning_ref_missing_year.b9
          fi
          cut -f4 -d"|" /data/temp_svp/temp_contact_email.txt > /data/temp_svp/temp_abname.txt
          grep -Fvxf /data/temp_svp/temp_abname.txt /data/temp_svp/temp_abname_ann.txt | awk '{gsub("$","|");printf $0}' > /data/temp_svp/miss_abname_ann.txt
          # awk '{gsub("$","|");printf $0}' /data/temp_svp/temp_abname.txt > /data/temp_svp/oneline_abname.txt
          oneline_abname=`awk '{gsub("$","|");printf $0}' /data/temp_svp/temp_abname.txt`
          awk -v var1="$biosample_id" -v var2="$ann_filename" -v var3="$oneline_abname" -v OFS="\t" '{print var2, "warning", "CMC0022", var1, "biosample=" var3, "ann=" $1 }' /data/temp_svp/miss_abname_ann.txt > /data/temp_svp/common_warning_abname.b9
          # check email and ab_name from contact
          check_contact_ann=`egrep -w "$contact_ann" /data/temp_svp/temp_contact_email.txt | wc -l`
          check_email_ann=`egrep -w "$email_ann" /data/temp_svp/temp_contact_email.txt | wc -l`
          if [ ${check_contact_ann} -eq 1 ]; then
            fgrep "$contact_ann" /data/temp_svp/temp_contact_email.txt > /data/temp_svp/temp_contact_email2.txt
            email=`cut -f2 -d"|" /data/temp_svp/temp_contact_email2.txt`
            if [ ${email_ann} != ${email} ]; then
              # echo "wrong email"
              awk -F"|" -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "CMC0021", var1, "biosample=" $2 }' /data/temp_svp/temp_contact_email2.txt > /data/temp_svp/common_warning_email.b9
            fi
          # contact incorrect but email is correct
          elif [ ${check_contact_ann} -eq 0 ] && [ ${check_email_ann} -eq 1 ]; then
            fgrep "$email_ann" /data/temp_svp/temp_contact_email.txt > /data/temp_svp/temp_contact_email2.txt
            contact=`cut -f3 -d"|" /data/temp_svp/temp_contact_email2.txt`
            if [ "${contact_ann}" != "${contact}" ]; then
              # echo "wrong contact"
              awk -F"|" -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "CMC0020", var1, "biosample=" $3 }' /data/temp_svp/temp_contact_email2.txt > /data/temp_svp/common_warning_contact.b9
            fi
          # contact and email are incorrect
          elif [ ${check_contact_ann} -eq 0 ] && [ ${check_email_ann} -eq 0 ]; then
            awk -F"|" -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "CMC0020", var1, "biosample=" $3 }' /data/temp_svp/temp_contact_email.txt > /data/temp_svp/common_warning_contact.b9
            len_email=`egrep -w "$email_ann" /data/temp_svp/temp_contact_email.txt | wc -l`
            if [ ${len_email} -eq 0 ]; then
              awk -F"|" -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "CMC0021", var1, "biosample=" $2 }' /data/temp_svp/temp_contact_email.txt > /data/temp_svp/common_warning_email.b9
            fi
          fi
        else
          echo "${filename}: Missing file /data/temp_svp/temp_contact_email.txt"
        fi
        # DRR bs_smp2drr.csv
        contact_dir="/srv/bs_smp2drr.csv"
        fgrep ${biosample_id} ${contact_dir} | cut -f2 > /data/temp_svp/temp_bs2drr.txt
        awk -F"\t" '$4=="sequence read archive"{print $5}' /data/temp_svp/common.txt > /data/temp_svp/ann_drr.txt
        test_drr=`wc -l /data/temp_svp/temp_bs2drr.txt | cut -f1 -d" "`
        test_ann_drr=`wc -l /data/temp_svp/ann_drr.txt | cut -f1 -d" "`
        # CMC0202
        if [ ${test_drr} -gt 0 ] && [ ${test_ann_drr} -gt 0 ] ; then
          grep -Fxvf /data/temp_svp/temp_bs2drr.txt /data/temp_svp/ann_drr.txt > /data/temp_svp/wrong_drr.txt
          if test -f "/data/temp_svp/wrong_drr.txt" ; then
            declare -i test_wrong_drr=`wc -l /data/temp_svp/wrong_drr.txt | cut -f1 -d " "`
            drr=`awk '{gsub("$","|");printf $0}' /data/temp_svp/temp_bs2drr.txt`
            if [ ${test_wrong_drr} -gt 0 ] ; then
              drr_ann=`awk '{gsub("$","|");printf $0}' /data/temp_svp/wrong_drr.txt`
              printf "${ann_filename}%s\twarning%s\tCMC0200%s\t"biosample="${drr}%s\t"ann="$drr_ann%s\n" > /data/temp_svp/common_warning_drr.b9
            fi
          fi
          grep -Fxvf /data/temp_svp/ann_drr.txt /data/temp_svp/temp_bs2drr.txt > /data/temp_svp/missing_drr.txt
          if test -f "/data/temp_svp/missing_drr.txt" ; then
            test_missing_drr=`wc -l /data/temp_svp/missing_drr.txt | cut -f1 -d " "`
            drr=`awk '{gsub("$","|");printf $0}' /data/temp_svp/temp_bs2drr.txt`
            if [ ${test_missing_drr} -gt 0 ] ; then
              drr_ann=`awk '{gsub("$","|");printf $0}' /data/temp_svp/missing_drr.txt`
              printf "${ann_filename}%s\twarning%s\tCMC0202%s\t"biosample="${drr}%s\t"ann="$drr_ann%s\n" > /data/temp_svp/common_warning_drr2.b9
            fi
          fi
        elif [ ${test_drr} -gt 0 ] && [ ${test_ann_drr} -eq 0 ] ; then
          awk -F"|" -v var1="$biosample_id" -v var2="$ann_filename" -v OFS="\t" '{print var2, "warning", "CMC0201", var1, "biosample_drr=" $1 }' /data/temp_svp/temp_bs2drr.txt > /data/temp_svp/common_warning_drr2.b9
        fi
      else
        echo "$filename: Missing biosample_id."
      fi
    else
      echo "$filename: Missing file /data/temp_svp/common.txt"
    fi
    numb_comm=`ls /data/temp_svp/common_warning_*.b9 | wc -l`
    if [ ${numb_comm} -gt 0 ]; then
      cat /data/temp_svp/common_warning_*.b9 >> /data/temp_svp/temp_warnings_common_check.b11
      rm -f /data/temp_svp/common_warning_*.b9
    fi
  else
    echo "$filename: Missing feature source."
  fi
done < /data/temp_svp/input_ids.txt

numb_warnings=`ls /data/temp_svp/*.b11 | wc -l`
if [ ${numb_warnings} -gt 0 ]; then
  cat /data/temp_svp/*.b11 > /data/temp_svp/warnings_common_check.tsv
fi
