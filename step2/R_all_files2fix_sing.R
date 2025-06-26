# dependencies:
# output of ddbj_mss_validation_v0.5.R
# list.of.packages <- c("data.table", "stringr")
# new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
# if(length(new.packages)) install.packages(new.packages, repos="https://ftp.yz.yamagata-u.ac.jp/pub/cran/")
# require(data.table)
# require(stringr)
# detect server
# server_hostname <- system("cat /proc/sys/kernel/hostname", intern = T)
# if(server_hostname[1] == "ddbjs1"){
#   directory <- "/home/andreaghelfi/backup_data_gw/scripts/tables" # ddbjs1 tables
#   scripts_dir <- "/home/andreaghelfi/backup_data_gw/scripts" # ddbjs1 scripts
# } else {
#   directory <- "/home/andrea/scripts/tables" # gw tables
#   scripts_dir <- "/home/andrea/scripts" # gw scripts
# }
allfiles2fix <- function() {
  # read output of ddbj_mss_validation
  line_log_files <- " wc -l /data/Rfixed/confirmation_report.tsv | cut -f1 -d\" \" "
  lines_log_files <- as.numeric(system(line_log_files, intern = T))
  if(lines_log_files > 0){
    log_file <- read.table("/data/Rfixed/confirmation_report.tsv", header = T, sep= "\t")
    log_file <- log_file[!is.na(log_file$biosample), ]
    log_file <- log_file[log_file$biosample != "not applicable", ]
    #len_log_file <- dim(log_file)[1]
    # curators_report <- fread("/data/Rfixed/curators_report.tsv", header = T, sep= "\t")
    # len_curators_report <- dim(curators_report)[1]
    fix_biosampledb <- log_file[log_file$action == "missing_biosample", ]
    len_fix_biosampledb <- dim(fix_biosampledb)[1]
    replace_ann <- log_file[(log_file$biosample != "Missing_value" & log_file$biosample != "missing"), ]
    # replace_ann <- log_file[(log_file$biosample != "Missing_value" | log_file$action != "missing_biosample"), ]
    replace_ann$action <- as.character(replace_ann$action)
    len_replace_ann <- length(unique(replace_ann$type))
    if(len_fix_biosampledb > 0){
      # fix_biosampledb, write a report with all missing qualifier values in BiosampleDB
      missingBiosampleDB <- as.data.frame(log_file[log_file$biosample == "Missing_value", c("source", "biosample_id_ann", "biosample", "ann_file")])
      len_missingBiosampleDB <- dim(missingBiosampleDB)[1]
      if(len_missingBiosampleDB > 0){
        write.table(missingBiosampleDB, "/data/Rfixed/missingBiosampleDB.tsv", row.names = F, col.names = T, quote = F, sep = "\t")
      }
    } # len_fix_biosampledb
    allfiles2fix <- data.frame(matrix(ncol = 6, nrow = 1))
    colnames(allfiles2fix) <- c('source', 'biosample_id_ann', 'biosample', 'ann_file', 'type', 'action')
    if(len_replace_ann > 0){
      i <- 1
      qualifiers_list <- as.character(unique(replace_ann$type))
      for(i in 1:len_replace_ann){
        qualifier <- qualifiers_list[i]
        warning_log <- as.data.frame(replace_ann[replace_ann$type == qualifier, c("source", "biosample", "ann_file")])
        if(qualifier == "country"){
          message_curators_report <- paste("\nFEATURE [", qualifier, "] requires to be REMOVED in the following files: \n", sep="")  
        }else{
          message_curators_report <- paste("\nQualifier [", qualifier, "] requires to be replaced in the following files: \n", sep="")
        }
        cat(message_curators_report)
        print(warning_log)
        message_confirmation <- "\nDo you like to change annotation file(s) (Yes or No)? \n"
        cat(message_confirmation)
        confirm_message_curators_report <- toupper(as.character(scan("stdin", character(), n=1, nlines = 1, quiet = T)))
        while(length(confirm_message_curators_report) == 0){
          cat("\nPlease, type Yes or No to confirm", "\n")
          cat(message_confirmation)
          confirm_message_curators_report <- toupper(as.character(scan("stdin", character(), n=1, nlines = 1, quiet = T)))
        }
        while(confirm_message_curators_report != "N" & confirm_message_curators_report != "NO" & confirm_message_curators_report != "Y" & confirm_message_curators_report != "YES"){
          cat("\nPlease, type Yes or No to confirm", "\n")
          cat(message_confirmation)
          confirm_message_curators_report <- toupper(as.character(scan("stdin", character(), n=1, nlines = 1, quiet = T)))
        }
        if(confirm_message_curators_report == "YES" | confirm_message_curators_report == "Y"){
          # create file with all qualifiers to be fixed, then make a new loop to fix ann file based on the information of log_file
          files2fix <- as.data.frame(replace_ann[replace_ann$type == qualifier, c('source', 'biosample_id_ann', 'biosample', 'ann_file', 'type', 'action')])
          allfiles2fix <- rbind(allfiles2fix, files2fix)
          # allfiles2fix$formated <- paste(allfiles2fix$type, allfiles2fix$biosample, sep="\t")
        }
      } # for len_replace_ann
      allfiles2fix <- allfiles2fix[!is.na(allfiles2fix$source), ]
      write.table(allfiles2fix, "/data/temp_autofix/allfiles2fix.log", row.names = F, col.names = T, quote = F, sep = "\t")
      write.table(unique(allfiles2fix[,1]), "/data/temp_autofix/allfilesnames2fix.log", row.names = F, col.names = F, quote = F)
    } # if len_replace_ann
  } # lines_log_files
  # allfiles2fix <- allfiles2fix[!is.na(allfiles2fix$source),]
} # allfiles2fix

allfiles2fix()
