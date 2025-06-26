# convert file to linux format, remove blank spaces and tab in the end of each line
# go to the directory were there are files with extension ann and fasta
# usage: sh convert-linuxformat_remove-blankspaces_v0.4.sh
# \r remove CRTL+M; awk NF remove blank lines (=show line when NF is not 0)
#!/bin/bash
while IFS= read -r filename; do
  ann_ext=".ann"
  ann_filename="${filename}${ann_ext}"
  awk '{ gsub("\r", "\n"); gsub("  ", " "); gsub(" \t", "\t"); gsub("\t ", "\t"); gsub(" $", ""); gsub("\t$", ""); gsub(" COMMON", "COMMON"); print }' ${ann_filename} > temp_autofix/temp_${ann_filename}
  awk NF temp_autofix/temp_${ann_filename} > Rfixed/${ann_filename}
  rm -rf temp_autofix/temp_${ann_filename} 
done < /data/temp_svp/input_ids.txt
