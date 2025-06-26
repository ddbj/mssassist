#!/bin/bash
# 
declare -i check_out_jParser=` ls out_jParser | wc -l`
if [ $check_out_jParser -gt 0 ]
then
  echo "jParser"
  cat out_jParser/*.txt > all_jParser.txt
  declare -i lines_out_jParser=`cut -c-2 all_jParser.txt | fgrep -c "JP"`
  if [ $lines_out_jParser -eq 0 ]
    then
      echo "There are NO errors/warnings detected by jParser."
    else
      echo "Errors/warnings were detected by jParser."
  fi
else
  echo "Not found jParser output files"
fi
declare -i check_out_transChecker=` ls out_tranChecker | wc -l`
if [ $check_out_transChecker -gt 0 ]
then
  echo "tranChecker"
  cat out_tranChecker/*.txt > all_tranChecker.txt
  declare -i lines_out_transChecker=`wc -l all_tranChecker.txt | cut -f1 -d" "`
  if [ $lines_out_transChecker -eq 0 ]
    then
      echo "There are NO errors/warnings detected by transChecker."
    else
      echo "Errors/warnings were detected by transChecker."
  fi
else
  echo "Not found transChecker output files"
fi
