require(data.table, quietly = T)
require(foreach, quietly = T)
require(doParallel, quietly = T)
pipe_rule_gtag <- function(){
  blocks <- fread("/data/temp_svp/index_split2fasta.txt", sep="\t", header=F)
  colnames(blocks) <- c("block", "entry_id")
  introns <- fread("/data/temp_svp/temp_gt_ag_rule_join_mRNA_introns.txt", sep=";", header=F)
  colnames(introns) <- c("entry_id", "nrow", "feature", "end_exon", "start_exon")
  introns$direction <- "forward"
  introns <- introns[!duplicated(introns[, c("entry_id", "end_exon", "start_exon")]),] 
  introns_compl <- fread("/data/temp_svp/temp_gt_ag_rule_join_mRNA_introns_compl.txt", sep=";", header=F)
  colnames(introns_compl) <- c("entry_id", "nrow", "feature", "end_exon", "start_exon")
  introns_compl$direction <- "reverse"
  introns_compl <- introns_compl[!duplicated(introns_compl[, c("entry_id", "end_exon", "start_exon")]),]
  introns <- rbind(introns, introns_compl)
  table <- merge(blocks, introns, by="entry_id")
  total_number_introns <- dim(table)[1]
  write.table(total_number_introns, "/data/temp_svp/total_number_introns.txt", row.names=F, col.names=F, append=F, quote=F)
  table$block_num <- as.numeric(sub("file_", "", table$block))
  list_of_blocks <- unique(table$block)
  len_list_of_blocks <- length(list_of_blocks)
  l <- 1
  if(len_list_of_blocks > 0){
    index_blocks <- fread("/data/temp_svp/index_split2fasta.txt", sep="\t", header=F)
    colnames(index_blocks) <- c("block_num", "entry")
    index_blocks <- index_blocks[!duplicated(index_blocks[, c("block_num")]),]
    entry_size <- fread("/data/temp_svp/temp_length_firstlastbases.txt", sep="\t", header=F)[,1:2]
    colnames(entry_size) <- c("entry", "length")
    index_blocks_size <- merge(index_blocks,entry_size,by="entry")
    total_blocks_size <- index_blocks_size$length
    big_blocks_pos <- which(total_blocks_size >= 2e+5)
    len_big_blocks_pos <- length(big_blocks_pos)
    big_blocks <- table[table$block_num <= len_big_blocks_pos,]
    total_entries <- unique(big_blocks$entry_id)
    len_total_entries <- length(total_entries)
    small_blocks <- table[table$block_num > len_big_blocks_pos,]
  }

  rule_small_blocks <- function(){
    # small_blocks
    list_small_blocks <- unique(small_blocks$block)
    len_small_blocks <- length(list_small_blocks)
    m <- 1
    for(m in 1:len_small_blocks){
      sm_block_id <- list_small_blocks[m]
      sm_block <- small_blocks[small_blocks$block == sm_block_id,]
      dir_blocks <- "/data/temp_svp/tmp"
      filename_sm_block <- paste(dir_blocks, sm_block_id, sep="/")
      groups <- fread(filename_sm_block, header=F, sep="%")
      colnames(groups) <- c("entry_id", "frag1")
      groups$entry_id <- sub(">","", groups$entry_id)
      # sm_block
      sm_block <- sm_block[order(sm_block$entry_id, sm_block$end_exon),]
      # intron positions
      sm_block$start_intron <- sm_block$end_exon + 1
      sm_block$start_intron2 <- sm_block$start_intron + 1
      sm_block$end_intron <- sm_block$start_exon - 1
      sm_block$end_intron2 <- sm_block$end_intron - 1
      len_sm_block <- dim(sm_block)[1]
      # add sequence
      introns_frag1 <- merge(sm_block, groups, by="entry_id")
      rm(groups)
      k <- 1
      for(k in 1:len_sm_block){
        introns_frag1$begin[k] <- substring(introns_frag1$frag1[k], introns_frag1$start_intron[k], introns_frag1$start_intron2[k])
        introns_frag1$end[k] <- substring(introns_frag1$frag1[k], introns_frag1$end_intron2[k], introns_frag1$end_intron[k])
      }
      # remove sequence
      introns_frag1 <- subset(introns_frag1, select=-c(frag1))
      # letter case
      introns_frag1$begin <- toupper(introns_frag1$begin)
      introns_frag1$end <- toupper(introns_frag1$end)
      error_trad359 <- introns_frag1[ ((introns_frag1$direction == "forward") & (introns_frag1$begin != "GT" | introns_frag1$end != "AG")) | ((introns_frag1$direction == "reverse") & (introns_frag1$begin != "CT" | introns_frag1$end != "AC")) , ]
      len_error_trad359 <- dim(error_trad359)[1]
      if(len_error_trad359 > 0){
        error_trad359 <- error_trad359[, c("entry_id", "nrow", "feature", "direction", "end_exon", "start_exon", "begin", "end")]
        fwrite(error_trad359, "/data/temp_svp/temp_out/error_trad359_small_blocks.tsv", row.names=F, col.names=F, append=T, sep="\t", quote=F)
      }
    }
  }

  rule_gtag <- function(entrya){
    # a <- big_blocks[grep(entrya, big_blocks$entry_id),] # bug do not use grep !
    a <- big_blocks[big_blocks$entry_id == entrya,]
    filea <- a$block[1]
    maxa <- max(a$start_exon)
    # round values up
    large_div <- ceiling(maxa/2e+6)
    if(large_div > 1){
      # histogram
      hista <- hist(a$start_exon, breaks = large_div ,right = T, plot = F)
      intervalsa <- hista$breaks
      countsa <- hista$counts
      len_countsa <- length(countsa)
      j <- 1
      for(j in 1:len_countsa){
        count1 <- countsa[j]
        if(count1 > 0){
          intervalhsc <- intervalsa[j+1]
          intervalh <- format(intervalhsc, scientific=F)
          intervallsc <- intervalsa[j]
          intervall <- intervallsc + 1
          line1 <- "egrep -w \"ENTRYA\" /data/temp_svp/tmp/FILEA | cut -f2 -d\"%\" | cut -cINTERVALL-INTERVALH"
          line1 <- sub("ENTRYA", entrya, line1)
          line1 <- sub("FILEA", filea, line1)
          line1 <- sub("INTERVALL", intervall, line1)
          line1 <- sub("INTERVALH", intervalh, line1)
          frag1 <- system(line1, intern=T)
          test_len_frag1 <- nchar(frag1)
          # work with hist intervals
          introns_frag1 <- a[(a$end_exon > intervallsc) & (a$start_exon <= intervalhsc),] # changed start_exon
          # correct exon positions
          introns_frag1$end_exon <- introns_frag1$end_exon - intervallsc
          introns_frag1$start_exon <- introns_frag1$start_exon - intervallsc
          # intron positions
          introns_frag1$start_intron <- introns_frag1$end_exon + 1
          introns_frag1$start_intron2 <- introns_frag1$start_intron + 1
          introns_frag1$end_intron <- introns_frag1$start_exon - 1
          introns_frag1$end_intron2 <- introns_frag1$end_intron - 1
          len_introns_frag1 <- dim(introns_frag1)[1]
          # add sequence
          introns_frag1$frag1 <- frag1
          k <- 1
          for(k in 1:len_introns_frag1){
            introns_frag1$begin[k] <- substring(introns_frag1$frag1[k], introns_frag1$start_intron[k], introns_frag1$start_intron2[k])
            introns_frag1$end[k] <- substring(introns_frag1$frag1[k], introns_frag1$end_intron2[k], introns_frag1$end_intron[k])
          }
          # remove sequence
          introns_frag1 <- subset(introns_frag1, select=-c(frag1))
          # letter case
          introns_frag1$begin <- toupper(introns_frag1$begin)
          introns_frag1$end <- toupper(introns_frag1$end)
          # include direction reverse
          error_trad359 <- introns_frag1[ ((introns_frag1$direction == "forward") & (introns_frag1$begin != "GT" | introns_frag1$end != "AG")) | ((introns_frag1$direction == "reverse") & (introns_frag1$begin != "CT" | introns_frag1$end != "AC")) , ]
          len_error_trad359 <- dim(error_trad359)[1]
          if(len_error_trad359 > 0){
            # re-correct exon positions
            error_trad359$end_exon <- error_trad359$end_exon + intervallsc
            error_trad359$start_exon <- error_trad359$start_exon + intervallsc
            error_trad359 <- error_trad359[, c("entry_id", "nrow", "feature", "direction", "end_exon", "start_exon", "begin", "end")]
            out_filename <- paste("/data/temp_svp/temp_out/error_trad359", entrya, j, sep="_")
            data.table::fwrite(error_trad359, out_filename, row.names=F, col.names=F, append=F, sep="\t", quote=F)
          }
        }
      }
    } else {
      # seq is lower than 2e+6, big blocks
      line1 <- "egrep -w \"ENTRYA\" /data/temp_svp/tmp/FILEA | cut -f2 -d\"%\" "
      line1 <- sub("ENTRYA", entrya, line1)
      line1 <- sub("FILEA", filea, line1)
      frag1 <- system(line1, intern=T)
      test_len_frag1 <- nchar(frag1)
      # work with whole seq
      introns_frag1 <- a
      # intron positions
      introns_frag1$start_intron <- introns_frag1$end_exon + 1
      introns_frag1$start_intron2 <- introns_frag1$start_intron + 1
      introns_frag1$end_intron <- introns_frag1$start_exon - 1
      introns_frag1$end_intron2 <- introns_frag1$end_intron - 1
      len_introns_frag1 <- dim(introns_frag1)[1]
      # add sequence
      introns_frag1$frag1 <- frag1
      k <- 1
      for(k in 1:len_introns_frag1){
        introns_frag1$begin[k] <- substring(introns_frag1$frag1[k], introns_frag1$start_intron[k], introns_frag1$start_intron2[k])
        introns_frag1$end[k] <- substring(introns_frag1$frag1[k], introns_frag1$end_intron2[k], introns_frag1$end_intron[k])
      }
      # remove sequence
      introns_frag1 <- subset(introns_frag1, select=-c(frag1))
      # letter case
      introns_frag1$begin <- toupper(introns_frag1$begin)
      introns_frag1$end <- toupper(introns_frag1$end)
      error_trad359 <- introns_frag1[ ((introns_frag1$direction == "forward") & (introns_frag1$begin != "GT" | introns_frag1$end != "AG")) | ((introns_frag1$direction == "reverse") & (introns_frag1$begin != "CT" | introns_frag1$end != "AC")) , ]

      len_error_trad359 <- dim(error_trad359)[1]
      if(len_error_trad359 > 0){
        error_trad359 <- error_trad359[, c("entry_id", "nrow", "feature", "direction", "end_exon", "start_exon", "begin", "end")]
        out_filename <- paste("/data/temp_svp/temp_out/error_trad359", entrya, sep="_")
        data.table::fwrite(error_trad359, out_filename, row.names=F, col.names=F, append=F, sep="\t", quote=F)
      }
    }
  }

  len_small_blocks <- dim(small_blocks)[1]
  if(len_small_blocks > 0){
    rule_small_blocks()
  }

  n.cores <- 8
  my.cluster <- parallel::makeCluster(
    n.cores,
    type = "PSOCK"
    )
  doParallel::registerDoParallel(cl = my.cluster)

  ptime <- system.time({
  foreach(i = 1:len_total_entries) %dopar% {
    entrya <- total_entries[i]
    rule_gtag(entrya)
  }
  })[3]

}
pipe_rule_gtag()
