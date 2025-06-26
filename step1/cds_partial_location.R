#!/usr/bin/Rscript --vanilla

args = commandArgs(trailingOnly=TRUE)
require(stringr, quietly = T)
ann_filename = args[1]

if(file.exists("/data/temp_svp/temp_length_firstlastbases.txt") & file.exists("/data/temp_svp/temp_join1_nr.txt")){
  len <- read.table("/data/temp_svp/temp_length_firstlastbases.txt", header=F, sep="\t", stringsAsFactors = FALSE)[,1:2]
  codon <- read.table("/data/temp_svp/temp_join1_nr.txt", header=F, sep=";", stringsAsFactors = FALSE)
  colnames(len) <- c("entry", "length")
  #len$length <- as.numeric(len$length)
  colnames(codon) <- c("entry", "feature", "codon_start", "codon_start_value", "codon_start_row", "location", "location_row")
  test_codon_start <- length(codon[codon$codon_start == "codon_start",1])
  if(test_codon_start > 0) {
    codon <- codon[codon$codon_start == "codon_start",]
    cds_partial_location <- merge(codon, len, by="entry")
    cds_partial_location$filename <- ann_filename
    # check errors 1 and 3
    check_error <- cds_partial_location[grep("<", cds_partial_location$location),]
    len_check_error <- dim(check_error)[1]
    if(len_check_error > 0){
      check_error$ann_location_start <- as.data.frame(str_split(check_error$location, "[.]", simplify=T))[,1]
      check_error$ann_location_end <- as.data.frame(str_split(check_error$location, "[.]", simplify=T))[,3]
      # err1: 5' partial <a..b
      check_error1 <- check_error[grep("<1", check_error$ann_location_start, invert= T),]
      len_check_error1 <- dim(check_error1)[1]
      if(len_check_error1 > 0){
        err1 <- check_error1[grep(">", check_error1$ann_location_end, invert= T),]
        len_err1 <- dim(err1)[1]
        if(len_err1 > 0){
          err1$ann_location_start <- sub("<", "", err1$ann_location_start)
          err1$ann_location_start <- as.numeric(err1$ann_location_start)
          err1$ann_location_end <- as.numeric(err1$ann_location_end)
          err1$tadashi_location <- paste("<1..",err1$ann_location_end ,sep="")
          err1$tadashi_codon_start_value <- err1$ann_location_start
        }
      }
      # err3: 5' and 3' partial <a..>b
      err3 <- check_error[grep(">", check_error$ann_location_end),]
      len_err3 <- dim(err3)[1]
      if(len_err3 > 0){
        err3$ann_location_start <- sub("<", "", err3$ann_location_start)
        err3$ann_location_start <- as.numeric(err3$ann_location_start)
        err3$ann_location_end <- sub(">", "", err3$ann_location_end)
        err3$ann_location_end <- as.numeric(err3$ann_location_end)
        err3a <- err3[err3$ann_location_start != 1 & err3$ann_location_end == err3$length,]
        len_err3a <- dim(err3a)[1]
        if(len_err3a > 0){
          err3a$tadashi_location <- paste("<1..>",err3a$ann_location_end ,sep="")
          err3a$tadashi_codon_start_value <- err3a$ann_location_start
        }
        err3b <- err3[err3$ann_location_start == 1 & err3$ann_location_end != err3$length ,]
        len_err3b <- dim(err3b)[1]
        if(len_err3b > 0){
          err3b$distance_err <- abs(err3b$length - err3b$ann_location_end)
          temp_err3b_tobefixed <- err3b[err3b$distance_err <= 2,]
          len_temp_err3b_tobefixed <- dim(temp_err3b_tobefixed)[1]
          if(len_temp_err3b_tobefixed > 0){
            temp_err3b_tobefixed$tadashi_location <- paste("<", temp_err3b_tobefixed$ann_location_start, "..>", temp_err3b_tobefixed$length, sep="")
          }
          temp_err3b_NOTtobefixed <- err3b[err3b$distance_err > 2,]
          len_temp_err3b_NOTtobefixed <- dim(temp_err3b_NOTtobefixed)[1]
          if(len_temp_err3b_NOTtobefixed > 0){
            temp_err3b_NOTtobefixed$tadashi_location <- NA
          }
          if(len_temp_err3b_tobefixed > 0 | len_temp_err3b_NOTtobefixed > 0){
            err3bfixed <- rbind(temp_err3b_tobefixed, temp_err3b_NOTtobefixed)
            err3bfixed$tadashi_codon_start_value <- NA
            err3bfixed <- subset(err3bfixed, select=-c(distance_err))
          }
        }
        err3c <- err3[err3$ann_location_start != 1 & err3$ann_location_end != err3$length ,]
        len_err3c <- dim(err3c)[1]
        if(len_err3c > 0){
          err3c$distance_err <- abs(err3c$length - err3c$ann_location_end)
          temp_err3c_tobefixed <- err3c[err3c$distance_err <= 2,]
          len_temp_err3c_tobefixed <- dim(temp_err3c_tobefixed)[1]
          if(len_temp_err3c_tobefixed > 0){
            temp_err3c_tobefixed$tadashi_location <- paste("<1..>", temp_err3c_tobefixed$length, sep="")
            temp_err3c_tobefixed$tadashi_codon_start_value <- temp_err3c_tobefixed$ann_location_start
          }
          temp_err3c_NOTtobefixed <- err3c[err3c$distance_err > 2,]
          len_temp_err3c_NOTtobefixed <- dim(temp_err3c_NOTtobefixed)[1]
          if(len_temp_err3c_NOTtobefixed > 0){
            temp_err3c_NOTtobefixed$tadashi_location <- NA
            temp_err3c_NOTtobefixed$tadashi_codon_start_value <- NA
          }
          if(len_temp_err3c_tobefixed > 0 | len_temp_err3c_NOTtobefixed > 0){
            err3cfixed <- rbind(temp_err3c_tobefixed, temp_err3c_NOTtobefixed)
            err3cfixed <- subset(err3cfixed, select=-c(distance_err))
          }
        }
      }
    }
    # err2: 3' partial a..>b
    check_error2 <- cds_partial_location[grep(">", cds_partial_location$location),]
    len_check_error2 <- dim(check_error2)[1]
    
    if(len_check_error2 > 0){
      
      err2 <- check_error2[grep("<", check_error2$location, invert=T),]
      len_err2 <- dim(err2)[1]

      if(len_err2 > 0){
        err2$ann_location_start <- as.data.frame(str_split(err2$location, "[.]", simplify=T))[,1]
        err2$ann_location_end <- as.data.frame(str_split(err2$location, ">", simplify=T))[,2]
        err2 <- err2[err2$ann_location_end != err2$length ,]
        len_err2 <- dim(err2)[1]
        if(len_err2 > 0){
          err2$ann_location_start <- as.numeric(err2$ann_location_start)
          err2$ann_location_end <- as.numeric(err2$ann_location_end)
          err2$distance_err <- abs(err2$length - err2$ann_location_end)
          temp_err2_tobefixed <- err2[err2$distance_err <= 2,]
          len_temp_err2_tobefixed <- dim(temp_err2_tobefixed)[1]
          if(len_temp_err2_tobefixed > 0){
            temp_err2_tobefixed$tadashi_location <- paste(temp_err2_tobefixed$ann_location_start, "..>", temp_err2_tobefixed$length, sep="")
          }
          temp_err2_NOTtobefixed <- err2[err2$distance_err > 2,]
          len_temp_err2_NOTtobefixed <- dim(temp_err2_NOTtobefixed)[1]
          if(len_temp_err2_NOTtobefixed > 0){
            temp_err2_NOTtobefixed$tadashi_location <- NA
          }else{
            temp_err2_NOTtobefixed <- c()
          }
          if(len_temp_err2_tobefixed > 0 | len_temp_err2_NOTtobefixed > 0){
            err2fixed <- rbind(temp_err2_tobefixed, temp_err2_NOTtobefixed)
            err2fixed$tadashi_codon_start_value <- NA
            err2fixed <- subset(err2fixed, select=-c(distance_err))
          }
        }
      }
    }
    # output file
    test_err1 <- exists("err1")
    if(test_err1) {
      len_err1 <- dim(err1)[1]
    }else{
      len_err1 <- 0
      err1 <- c()
    }
    test_err2fixed <- exists("err2fixed")
    if(test_err2fixed) {
      len_err2fixed <- dim(err2fixed)[1]
    }else{
      len_err2fixed <- 0
      err2fixed <- c()
    }
    test_err3a <- exists("err3a")
    if(test_err3a) {
      len_err3afixed <- dim(err3a)[1]
    }else{
      len_err3afixed <- 0
      err3a <- c()
    }
    test_err3bfixed <- exists("err3bfixed")
    if(test_err3bfixed) {
      len_err3bfixed <- dim(err3bfixed)[1]
    }else{
      len_err3bfixed <- 0
      err3bfixed <- c()
    }
    test_err3cfixed <- exists("err3cfixed")
    if(test_err3cfixed) {
      len_err3cfixed <- dim(err3cfixed)[1]
    }else{
      len_err3cfixed <- 0
      err3cfixed <- c()
    }
    if(len_err1 > 0 | len_err2fixed > 0 | len_err3afixed > 0 | len_err3bfixed > 0 | len_err3cfixed > 0){
      cds_partial_location_error <- rbind(err1,err2fixed,err3a,err3bfixed,err3cfixed)
      write.table (cds_partial_location_error, "/data/temp_svp/autofix_cds_partial_location_error.tsv", row.names=F, col.names=F, quote=F, sep="\t", append = T)
      cds_partial_location_error <- cds_partial_location_error[, c("filename", "entry", "feature", "codon_start_value", "tadashi_codon_start_value", "location", "tadashi_location", "length")]
      write.table (cds_partial_location_error, "/data/temp_svp/temp_cds_partial_location_error.tsv", row.names=F, col.names=F, quote=F, sep="\t", append = T)
    }
  }
}
