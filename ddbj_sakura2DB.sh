#!/bin/bash
############################################################################
# ddbj_sakura2DB
############################################################################
# Developed by Andrea Ghelfi 
# Updated by Andrea Ghelfi 2025.4.3 (2025 new supercomputer settings)
# Please, do not change filenames after run ddbj_mss_validation or ddbj_autofix.
# This script runs on workdir, for example: mass-data/kumiko-0004/20220127/
# It will automatically identify the ann and fasta files.
# 
############################################################################
BASE="/home/w3const/mssassist"
# scripts="/home/andrea/scripts/"

mkdir -p ~/temp_sakura2DB
mkdir -p temp_svp
rm -rf ~/temp_sakura2DB/filesINsakura2DB.txt
rm -rf ~/temp_sakura2DB/lines2run.txt
rm -rf ~/temp_sakura2DB/run_sakura2DB.sh
rm -rf ~/temp_sakura2DB/all_ann_organisms.list
rm -rf ~/temp_sakura2DB/found_viruses_ann.txt
rm -rf ~/temp_sakura2DB/missing_fasta_files.list
rm -rf ~/temp_sakura2DB/input_ids.txt

date=`pwd | rev | cut -f1 -d"/" | rev`
check_date=`echo $date | awk '{year=substr($0,0,4); month=substr($0,5,2); day=substr($0,7,2); print year"/"month"/"day}'`
date "+%Y/%m/%d" -d $check_date > /dev/null  2>&1
is_valid=$?
if [[ $is_valid -eq 0 ]]; then
  mass_id=`pwd | rev | cut -f2 -d"/" | rev`
  pwd | rev | cut -f1 -d"/" | rev > ~/temp_sakura2DB/date.txt
  echo "Date is: "$date" and MASS_ID is: "$mass_id". Is it correct (y/n)?"
  read answer1
  form_ans1=`echo ${answer1^^}`
  if [[ $form_ans1 = "Y" ]]; then
    dir_Rfixed="Rfixed/"
    if [[ -d "$dir_Rfixed" ]]; then
      ls Rfixed/*.fasta | awk 'BEGIN{RS="."; FS="/"}NF>1{print $NF}' > ~/temp_sakura2DB/temp_rfixed_fasta_files.list
      while IFS= read -r test_ann; do
        test_ann_file=$test_ann".ann"
        test -f Rfixed/$test_ann_file
        is_ann_rfixed=$?
        if [[ $is_ann_rfixed -eq 1 ]]; then
          test -f $test_ann_file
          is_ann=$?
          if [[ $is_ann -eq 0 ]]; then # true==0
            cp $test_ann_file Rfixed/$test_ann_file
            echo "Copied" $test_ann_file "to Rfixed directory from workdir"
          elif [[ $is_ann -eq 1 ]]; then
            echo "Missing" $test_ann_file "on Rfixed directory"
            echo "Missing" $test_ann_file "on Rfixed directory" > ~/temp_sakura2DB/missing_fasta_files.list
          fi
        fi
      done < ~/temp_sakura2DB/temp_rfixed_fasta_files.list
    else
      ls *.ann |rev | cut -c5- | rev > ~/temp_sakura2DB/input_ids_ann.txt
      ls *.fasta |rev | cut -c7- | rev > ~/temp_sakura2DB/input_ids_fasta.txt
      grep -Fxf ~/temp_sakura2DB/input_ids_ann.txt ~/temp_sakura2DB/input_ids_fasta.txt > ~/temp_sakura2DB/input_ids.txt
      declare -i test1_ann=` wc -l ~/temp_sakura2DB/input_ids_ann.txt | cut -f1 -d" "`
      declare -i test1_ids=` wc -l ~/temp_sakura2DB/input_ids.txt | cut -f1 -d" "`
      if [[ ${test1_ann} -gt ${test1_ids} ]]; then 
        echo "Pair of ANN and Fasta files are not matching." > ~/temp_sakura2DB/missing_fasta_files.list
      fi
    fi
    # end of check
    if [[ ! -f ~/temp_sakura2DB/missing_fasta_files.list ]]; then
      echo "Pair of ANN and Fasta files are correct."
      # Check if someone has ann/fasta/FF files in the sakura2DB directory
      while IFS= read -r curator_name; do
        find /home/$curator_name/sakura2DB -maxdepth 1 -type f >> ~/temp_sakura2DB/filesINsakura2DB.txt
      done < ${BASE}/tsunami/list_curators.txt
      declare -i filesINsakura2DB=`grep -c 'fasta\|ann\|FF' ~/temp_sakura2DB/filesINsakura2DB.txt`
      filesINsakura2DB=0 # attention not checking if someone is running sakura2DB
      if [[ $filesINsakura2DB -ge 1 ]]; then
        whoisrunning=`grep -r -m1 '.fasta\|.ann\|.FF\|.ff' ~/temp_sakura2DB/filesINsakura2DB.txt | cut -f3 -d"/"`
        echo "There are files in the sakura2DB directory. Please, wait" $whoisrunning "finish the job."
      fi
      declare -i whoisrunningi=`echo ${#whoisrunning}`
      whoisrunningi=0 # not checking who is running sakura2DB
      if [[ $whoisrunningi -eq 0 ]]; then
        # copy revised files to workdir
        dir_Rfixed="Rfixed/"
        if [[ -d "$dir_Rfixed" ]]; then
          # if there are dir Rfixed, move original files to before_revision
          dir_before_revision="before_revision/"
          form_ans2="Y"
          if [[ ! -d "$dir_before_revision" ]]; then
            mkdir -p $dir_before_revision
            mv *.ann *.fasta $dir_before_revision
            echo "Moving ann and fasta files from workdir to before_revision."
            cp $dir_Rfixed*.ann $dir_Rfixed*.fasta .
            echo "Copied ann and fasta files from Rfixed to workdir."
          fi
        else
          echo "Missing directory Rfixed. Are you sure the files on workdir are already fixed (y/n)?"
          read answer2
          form_ans2=`echo ${answer2^^}`
        fi
        if [[ $form_ans2 = "Y" ]]; then
          date=`pwd | rev | cut -f1 -d"/" | rev`
          mass_id=`pwd | rev | cut -f2 -d"/" | rev`
          pwd | rev | cut -f1 -d"/" | rev > ~/temp_sakura2DB/date.txt
          pwd > ~/temp_sakura2DB/workdir.txt
          workdir=`pwd`
          # confirm if filenames have date and mass_id, if not change filename.
          ls *.ann |rev | cut -c5- | rev > ~/temp_sakura2DB/input_ids_ann.txt
          ls *.fasta |rev | cut -c7- | rev > ~/temp_sakura2DB/input_ids_fasta.txt
          grep -Fxf ~/temp_sakura2DB/input_ids_ann.txt ~/temp_sakura2DB/input_ids_fasta.txt > ~/temp_sakura2DB/input_ids.txt
          basefilename="$date$mass_id"
          declare -i test_basefilename=`egrep $basefilename ~/temp_sakura2DB/input_ids.txt | wc -l `
          #declare -i len_input_ids=`wc -l ~/temp_sakura2DB/input_ids.txt | cut -f1 -d " " `
          if [[ $test_basefilename -eq 0 ]]; then
            while IFS= read -r filename; do
              ann_ext=".ann"
              ann_filename="$filename$ann_ext"
              fasta_ext=".fasta"
              fasta_filename="$filename$fasta_ext"
              awk -F"\t" -v OFS="\t" -v var1="$ann_filename" '$4=="organism"{print var1, $5; exit;}' $ann_filename >> ~/temp_sakura2DB/all_ann_organisms.list
              new_ann="$basefilename$ann_filename"
              new_fasta="$basefilename$fasta_filename"
              mv $ann_filename $new_ann
              mv $fasta_filename $new_fasta
            done < ~/temp_sakura2DB/input_ids.txt
            ls *.ann |rev | cut -c5- | rev > ~/temp_sakura2DB/input_ids_ann.txt
            ls *.fasta |rev | cut -c7- | rev > ~/temp_sakura2DB/input_ids_fasta.txt
            grep -Fxf ~/temp_sakura2DB/input_ids_ann.txt ~/temp_sakura2DB/input_ids_fasta.txt > ~/temp_sakura2DB/input_ids.txt
          else
            while IFS= read -r filename; do
              ann_ext=".ann"
              ann_filename="$filename$ann_ext"
              awk -F"\t" -v OFS="\t" -v var1="$ann_filename" '$4=="organism"{print var1, $5; exit;}' $ann_filename >> ~/temp_sakura2DB/all_ann_organisms.list
            done < ~/temp_sakura2DB/input_ids.txt
          fi
          # end of change filename
          # Source organism
          cut -f2 ~/temp_sakura2DB/all_ann_organisms.list | sort | uniq > ~/temp_sakura2DB/unique_ann_organisms.list
          while IFS="\t" read -r organism_name; do
            awk -F"\t" -v var3="$organism_name" '$1 == var3 {print $1}' ${BASE}/tables/virus_phage.list >> ~/temp_sakura2DB/found_viruses_ann.txt
          done < ~/temp_sakura2DB/unique_ann_organisms.list
          declare -i len_ann_org=`wc -l ~/temp_sakura2DB/found_viruses_ann.txt | cut -f1 -d" "`
          # Organelle: testing only one file; I am assuming that all files in the workdir are same filetype
          onefile=`head -n1 ~/temp_sakura2DB/input_ids.txt`
          ann_onefile=$onefile".ann"
          # v1.5
          declare -i p1=`fgrep -n -m1 "source" ${ann_onefile} | cut -f1 -d":"`
          head -n$p1 ${ann_onefile} > temp_svp/source.txt
          organelle=`awk -F"\t" '$4 == "organelle"{ print $5}' temp_svp/source.txt`
          declare -i organellei=`echo ${#organelle}`
          hostname=`hostname`
          
          bash ${BASE}/ddbj_filetype.sh #if Rfixed read files in Rfixed dir
          if [[ -f temp_svp/filetype.tsv ]]; then
            cut -f 2 temp_svp/filetype.tsv | sort |uniq > temp_svp/uniq_filetype.txt
          fi
          if [[ -f temp_svp/uniq_filetype.txt ]]; then
          declare -i uniq_filetypei=`wc -l temp_svp/uniq_filetype.txt | cut -f1 -d" "`
            if [[ ${uniq_filetypei} -eq 1 ]]; then
              curator=$(whoami)
              multiple_filetypes=0
              filetype=`cat temp_svp/uniq_filetype.txt`
              if [[ ${filetype} = "WGS" ]]; then # consider UMSS prefixes 1/4
                echo "check point WGS"
                # attention set -D 7 instead of -D 6
                bash ${BASE}/get_wgs_prefix.sh
                python3 ${BASE}/increment_6digits_prefix.py WGS
                # actual
                actual_conv=`cat ~/temp_sakura2DB/last_prefix_actual_conv.txt`
                actual_umss=`cat ~/temp_sakura2DB/last_prefix_actual_umss.txt`
                echo -e "last prefix actual: (1) conventional="${actual_conv}"; (2) UMSS="${actual_umss}
                # test
                test_conv=`cat ~/temp_sakura2DB/last_prefix_test_conv.txt`
                test_umss=`cat ~/temp_sakura2DB/last_prefix_test_umss.txt`
                echo -e "last prefix test: (1) conventional="${test_conv}"; (2) UMSS="${test_umss}
                next=`cat ~/temp_sakura2DB/next_prefix.txt`
                cat ~/temp_sakura2DB/prefix_input_ids.txt
                awk -F"\t" -v var1="$curator" -v var2="$date" -v var3="$mass_id" '{print "/home/"var1"/sakura2DB/sakura2DB -A", $1, "-D 7 -U", var1, "-P", var1, "-S", $2".ann,"$2".fasta", "-x",$2".ann", "-s",$2".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/prefix_input_ids.txt > ~/temp_sakura2DB/lines2run.txt
              
              elif [[ ${filetype} = "TPA-WGS" ]]; then # consider UMSS prefixes 2/4
                # attention set -D 7 instead of -D 6
                bash ${BASE}/get_tpa_wgs_prefix.sh
                python3 ${BASE}/increment_6digits_prefix.py TPA-WGS
                # actual
                actual_conv=`cat ~/temp_sakura2DB/last_prefix_actual_conv.txt`
                actual_umss=`cat ~/temp_sakura2DB/last_prefix_actual_umss.txt`
                echo -e "last prefix actual: (1) conventional="${actual_conv}"; (2) UMSS="${actual_umss}
                # test
                test_conv=`cat ~/temp_sakura2DB/last_prefix_test_conv.txt`
                test_umss=`cat ~/temp_sakura2DB/last_prefix_test_umss.txt`
                echo -e "last prefix test: (1) conventional="${test_conv}"; (2) UMSS="${test_umss}
                next=`cat ~/temp_sakura2DB/next_prefix.txt`
                cat ~/temp_sakura2DB/prefix_input_ids.txt
                # building sakura2DB command lines
                awk -F"\t" -v var1="$curator" -v var2="$date" -v var3="$mass_id" '{print "/home/"var1"/sakura2DB/sakura2DB -A", $1, "-D 7 -U", var1, "-P", var1, "-S", $2".ann,"$2".fasta", "-x",$2".ann", "-s",$2".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/prefix_input_ids.txt > ~/temp_sakura2DB/lines2run.txt

              elif [[ ${filetype} = "TPA-TSA" ]]; then
                bash ${BASE}/get_tpa_tsa_prefix.sh
                last_actual=`cat ~/temp_sakura2DB/last_prefix_actual.txt`
                last_test=`cat ~/temp_sakura2DB/last_prefix_test.txt`
                next=`cat ~/temp_sakura2DB/next_prefix.txt`
                echo -e "Last prefix -test: "$last_test"\nLast prefix -actual: "$last_actual
                cat ~/temp_sakura2DB/prefix_input_ids.txt
                # building sakura2DB command lines
                awk -F"\t" -v var1="$curator" -v var2="$date" -v var3="$mass_id" '{print "/home/"var1"/sakura2DB/sakura2DB -A", $1, "-D 6 -U", var1, "-P", var1, "-S", $2".ann,"$2".fasta", "-x",$2".ann", "-s",$2".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/prefix_input_ids.txt > ~/temp_sakura2DB/lines2run.txt
              elif [[ ${filetype} = "TLS" ]]; then # consider UMSS prefixes 3/4
                bash ${BASE}/get_tls_prefix.sh
                # actual
                actual_conv=`cat ~/temp_sakura2DB/last_prefix_actual_conv.txt`
                actual_umss=`cat ~/temp_sakura2DB/last_prefix_actual_umss.txt`
                echo -e "last prefix actual: (1) conventional="${actual_conv}"; (2) UMSS="${actual_umss}
                # test
                test_conv=`cat ~/temp_sakura2DB/last_prefix_test_conv.txt`
                test_umss=`cat ~/temp_sakura2DB/last_prefix_test_umss.txt`
                echo -e "last prefix test: (1) conventional="${test_conv}"; (2) UMSS="${test_umss}
                next=`cat ~/temp_sakura2DB/next_prefix.txt`

                cat ~/temp_sakura2DB/prefix_input_ids.txt
                # building sakura2DB command lines
                awk -F"\t" -v var1="$curator" -v var2="$date" -v var3="$mass_id" '{print "/home/"var1"/sakura2DB/sakura2DB -A", $1, "-D 6 -U", var1, "-P", var1, "-S", $2".ann,"$2".fasta", "-x",$2".ann", "-s",$2".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/prefix_input_ids.txt > ~/temp_sakura2DB/lines2run.txt
              elif [[ ${filetype} = "TSA" ]]; then # consider UMSS prefixes 4/4
                bash ${BASE}/get_tsa_prefix.sh
                # actual
                actual_conv=`cat ~/temp_sakura2DB/last_prefix_actual_conv.txt`
                actual_umss=`cat ~/temp_sakura2DB/last_prefix_actual_umss.txt`
                echo -e "last prefix actual: (1) conventional="${actual_conv}"; (2) UMSS="${actual_umss}
                # test
                test_conv=`cat ~/temp_sakura2DB/last_prefix_test_conv.txt`
                test_umss=`cat ~/temp_sakura2DB/last_prefix_test_umss.txt`
                echo -e "last prefix test: (1) conventional="${test_conv}"; (2) UMSS="${test_umss}
                next=`cat ~/temp_sakura2DB/next_prefix.txt`
                cat ~/temp_sakura2DB/prefix_input_ids.txt
                # building sakura2DB command lines
                awk -F"\t" -v var1="$curator" -v var2="$date" -v var3="$mass_id" '{print "/home/"var1"/sakura2DB/sakura2DB -A", $1, "-D 6 -U", var1, "-P", var1, "-S", $2".ann,"$2".fasta", "-x",$2".ann", "-s",$2".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/prefix_input_ids.txt > ~/temp_sakura2DB/lines2run.txt
              elif [[ ${filetype} = "ENV" || ${filetype} = "general" ]]; then
                echo -e "Data is ENV or General. Prefix is: LC"
                awk -F"\t" -v var1="$curator" -v var2="$date" -v var3="$mass_id" '{print "/home/"var1"/sakura2DB/sakura2DB -A LC -U", var1, "-P", var1, "-S", $1".ann,"$1".fasta", "-x",$1".ann", "-s",$1".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/input_ids.txt > ~/temp_sakura2DB/lines2run.txt
              elif [[ ${filetype} = "TPA-assembly" ]]; then
                echo -e "Data is TPA-assembly. Prefix is: BR"
                awk -F"\t" -v var1="$curator" -v var2="$date" -v var3="$mass_id" '{print "/home/"var1"/sakura2DB/sakura2DB -A BR -U", var1, "-P", var1, "-S", $1".ann,"$1".fasta", "-x",$1".ann", "-s",$1".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/input_ids.txt > ~/temp_sakura2DB/lines2run.txt
              elif [[ ${filetype} = "MAGs_CompleteGenome" ]]; then
                option1=1
                option2=2
                form_ans3="N"
                while [[ ${form_ans3} = "N" ]]; do
                  echo -e "Data is MAGs_CompleteGenome. Prefix: type 1 for AP or 2 for LC."
                  read answer_prefix_mags
                  while ! [[ ${answer_prefix_mags} -eq ${option1} || ${answer_prefix_mags} -eq ${option2} ]] ; do
                    echo "Enter prefix: type 1 for AP or 2 for LC (default 1)"
                    read answer_prefix_mags
                  done
                  if [[ ${answer_prefix_mags} -eq 1 ]]; then
                    prefix_mags="AP"
                  elif [[ ${answer_prefix_mags} -eq 2 ]]; then
                    prefix_mags="LC"
                  fi
                  echo -e "Prefix is: "${prefix_mags}". Confirm (y/n)?"
                  read confirm_prefix_mags
                  form_ans3=`echo ${confirm_prefix_mags^^}`
                  if [[ $form_ans3 = "Y" ]]; then
                    awk -F"\t" -v var1="$curator" -v var2="$date" -v var3="$mass_id" -v var4="$prefix_mags" '{print "/home/"var1"/sakura2DB/sakura2DB -A", var4, "-U", var1, "-P", var1, "-S", $1".ann,"$1".fasta", "-x",$1".ann", "-s",$1".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/input_ids.txt > ~/temp_sakura2DB/lines2run.txt
                  fi
                done
              elif [[ ${filetype} = "complete_genome" ]]; then
                if [[ ${len_ann_org} -eq 0 && ${organellei} -eq 0 ]]; then
                  echo -e "Data is complete genome. Prefix is: AP"
                  # building sakura2DB command lines
                  awk -F"\t" -v var1="$curator" -v var2="$date" -v var3="$mass_id" '{print "/home/"var1"/sakura2DB/sakura2DB -A AP -U", var1, "-P", var1, "-S", $1".ann,"$1".fasta", "-x",$1".ann", "-s",$1".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/input_ids.txt > ~/temp_sakura2DB/lines2run.txt
                elif [[ ${len_ann_org} -gt 0 || ${organellei} -gt 0 ]]; then
                  echo -e "Data is organelle or virus. Prefix is: LC"
                  awk -F"\t" -v var1="$curator" -v var2="$date" -v var3="$mass_id" '{print "/home/"var1"/sakura2DB/sakura2DB -A LC -U", var1, "-P", var1, "-S", $1".ann,"$1".fasta", "-x",$1".ann", "-s",$1".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/input_ids.txt > ~/temp_sakura2DB/lines2run.txt
                fi
              else
                form_ans1="N"
                while [[ ${form_ans1} = "N" ]]; do
                  echo -e "Filetype is unknown. Enter prefix:"
                  read answer_prefix
                  echo "Prefix is: "${answer_prefix} " Confirm set_id (version) (y/n)?"
                  read answer1
                  form_ans1=`echo ${answer1^^}`
                  if [[ ${form_ans1} = "Y" ]]; then
                    awk -F"\t" -v var1="${curator}" -v var2="${date}" -v var3="${mass_id}" -v var4="${answer_prefix}" '{print "/home/"var1"/sakura2DB/sakura2DB -A", var4, "-U", var1, "-P", var1, "-S", $1".ann,"$1".fasta", "-x",$1".ann", "-s",$1".fasta", "-m Fexcel", "-a", var2, "-T", var3}' ~/temp_sakura2DB/input_ids.txt > ~/temp_sakura2DB/lines2run.txt
                  fi
                done
              fi
            elif [[ ${uniq_filetypei} -gt 1 ]]; then
              echo -e "There are multiple filetypes in this workdir."
              multiple_filetypes=1
            fi
          fi
          echo "Command line(s) are on file ~/temp_sakura2DB/lines2run.txt"
          echo " Select:
          (1) Proceed with registration on -test
          (2) Change prefix
          (3) Cancel registration "
          read answer3
          while ! [[ ${answer3} -eq 1 || ${answer3} -eq 2 || ${answer3} -eq 3  ]] ; do
            echo " Select:
            (1) Proceed with registration on -test
            (2) Change prefix
            (3) Cancel registration "
            read answer3
          done

          if [[ ${answer3} -eq 1 ]]; then
            form_ans3="Y";
            run_sakura=1
          elif [[ ${answer3} -eq 2 ]]; then
            #statements
            echo "Type prefix:"
            read manual_prefix
            echo "Confirm prefix (y/n): " ${manual_prefix}
            read ans_confirm
            confirm_manpre=`echo ${ans_confirm^^}`
            while [[ ${confirm_manpre} != "Y" ]] ; do
              echo "Type prefix:"
              read manual_prefix
              echo "Confirm prefix (y/n): " ${manual_prefix}
              read ans_confirm
              confirm_manpre=`echo ${ans_confirm^^}`
            done
            if [[ ${confirm_manpre} = "Y" ]]; then
              pre2change=`awk 'NR==1{print $3}' ~/temp_sakura2DB/lines2run.txt`
              mv ~/temp_sakura2DB/lines2run.txt ~/temp_sakura2DB/temp_lines2run.txt
              awk -v var1="${pre2change}" -v var2="${manual_prefix}" '{gsub(var1,var2); print $0}' ~/temp_sakura2DB/temp_lines2run.txt > ~/temp_sakura2DB/lines2run.txt
              form_ans3="Y"
              run_sakura=1
            else
              form_ans3="N"
              run_sakura=0
            fi

          elif [[ ${answer3} -eq 3 ]]; then
            #statements
            form_ans3="N"
            run_sakura=0

            echo ${form_ans3} 
          fi

          # Start sakura2DB: -test
          filesINsakura2DB=0
          ffmaker_pid=0
          if [[ $filesINsakura2DB -eq 0 && $ffmaker_pid -eq 0 && $run_sakura -eq 1 && $multiple_filetypes -eq 0 ]]; then
            basefilename=$date$mass_id
            curator=`whoami`
            echo "Starting to copy files to sakura2DB..."
            cp ~/temp_sakura2DB/prefix_input_ids.txt $basefilename* /home/$curator/sakura2DB
            mkdir -p sakura_test
            mkdir -p sakura_actual
            echo "Going to the directory sakura2DB..."
            cd /home/$curator/sakura2DB
            pwd=`pwd`
            date=`cat ~/temp_sakura2DB/date.txt`
            echo "You are in the directory: "$pwd
            echo "Using curator="$curator" and date="$date
            cat ${BASE}/sakura2DBshell.txt ~/temp_sakura2DB/lines2run.txt > ~/temp_sakura2DB/run_sakura2DB.sh
            echo "Command line(s) are on file ~/temp_sakura2DB/run_sakura2DB.sh"
            # at103
            if [[ $filetype = "WGS" || $filetype = "TPA-WGS" || $filetype = "TPA-TSA" ]]; then
              bash ${BASE}/run_sakura2DB_wtest.sh
            # at102
            elif [[ $filetype = "complete_genome" || $filetype = "general" || $filetype = "ENV" || $filetype = "TPA-assembly" || $filetype = "MAGs-CompleteGenome" ]]; then
              bash ${BASE}/run_sakura2DB_gtest.sh
            # at101
            elif [[ $filetype = "TSA" || $filetype = "TLS" ]]; then
              bash ${BASE}/run_sakura2DB_etest.sh
            fi
            egrep "WAR" *.report > ~/temp_sakura2DB/sakura2DB_warning.report
            declare -i error_log=`wc -l ~/temp_sakura2DB/sakura2DB_warning.report | cut -f1 -d" "`
            if [[ $error_log -gt 0 ]]; then
              cat ~/temp_sakura2DB/sakura2DB_warning.report
              echo "There are ["$error_log"] WAR on the sakura report files."
            fi
            egrep "ERROR" *.report > ~/temp_sakura2DB/sakura2DB_error.report
            declare -i error_log=`wc -l ~/temp_sakura2DB/sakura2DB_error.report | cut -f1 -d" "`
            if [[ $error_log -gt 0 ]]; then
              cat ~/temp_sakura2DB/sakura2DB_error.report
              echo "There are ["$error_log"] ERROR(s) on the sakura report files."
            fi
            workdir=`cat ~/temp_sakura2DB/workdir.txt`
            sakura_dir="$workdir/sakura_test"
            echo "Moving output files to sakura_test dir: "$sakura_dir
            mv *trz* *txt *$curator* ${sakura_dir}
            echo "Do you like to run sakura2DB -actual now (y/n)?"
            read answer4
            form_ans4=`echo ${answer4^^}`
          elif [[ $multiple_filetypes -eq 1 ]]; then
            echo "There are multiple filetypes in this workdir. Registration was suspended."
          else
            echo "Registration on db-test stopped by curator"
          fi
          # Start sakura2DB: -actual
          cat ${BASE}/sakura2DBshell.txt ~/temp_sakura2DB/lines2run.txt > ~/temp_sakura2DB/run_sakura2DB.sh
          echo "Command line(s) are on file ~/temp_sakura2DB/run_sakura2DB.sh"

          if [[ $form_ans4 = "Y" ]] ; then
            # at103
            if [[ $filetype = "WGS" || $filetype = "TPA-WGS" || $filetype = "TPA-TSA" ]]; then
              bash ${BASE}/run_sakura2DB_wactual.sh
            # at102
            elif [[ $filetype = "complete_genome" || $filetype = "general" || $filetype = "ENV" || $filetype = "TPA-assembly" || $filetype = "MAGs-CompleteGenome" ]]; then
              bash ${BASE}/run_sakura2DB_gactual.sh
              echo "Running sakura2DB on -actual. Filetype is: " ${filetype}
            # at101
            elif [[ $filetype = "TSA" || $filetype = "TLS" ]]; then
              bash ${BASE}/run_sakura2DB_eactual.sh
            fi
            echo "Finished sakura2DB. Moving files to workdir."
            workdir=`cat ~/temp_sakura2DB/workdir.txt`
            sakura_dir="$workdir/sakura_actual"
            mv *trz* *txt *$curator* ${sakura_dir}
            rm -rf *.ann *.fasta
            cd ${sakura_dir}
            mkdir -p acclist_dir
            ls *.acclist.txt > sk_acclist.txt
            awk -v var1="$date" -F"$date" '{ print "cp " $0, "acclist_dir/" var1 $2}' sk_acclist.txt > change_filename.sh
            bash change_filename.sh
            rm -rf sk_acclist.txt change_filename.sh
            cd ${workdir}
            cp -Rf ~/temp_sakura2DB ${workdir}
            chgrp -Rf mass-adm sakura_test/ sakura_actual/ temp_sakura2DB/ before_revision/ *.ann *.fasta
            chmod -Rf 775 sakura_test/ sakura_actual/ temp_sakura2DB/ before_revision/
            chmod -f 664 sakura_test/* sakura_actual/*trz*  sakura_actual/*txt sakura_actual/*$curator* sakura_test/acclist_dir/*.txt sakura_actual/acclist_dir/*.txt temp_sakura2DB/* *.ann *.fasta
          elif [[ $form_ans4 = "N" ]]; then
            echo "You didn't run sakura2DB - actual."
            workdir=`cat ~/temp_sakura2DB/workdir.txt`
            cp -Rf ~/temp_sakura2DB ${workdir}
            rm -rf *.ann *.fasta
            cd ${workdir}
            chgrp -Rf mass-adm temp_sakura2DB/ temp_svp/ before_revision/ *.ann *.fasta
            chmod -Rf 775 temp_sakura2DB/ temp_svp/ before_revision/
            chmod -f 664 temp_sakura2DB/* temp_svp/* *.ann *.fasta
          fi
        fi
      fi
    else
      echo "Exit ddbj_sakura2DB"
    fi
  else
    echo "Workdir has wrong path (mass-data/MASS_ID/DATE)"
  fi
else
  echo "Date or directory is incorrect make sure workdir has the path: mass-data/MASS_ID/DATE"
fi
