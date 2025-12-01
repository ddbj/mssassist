# develop format for output files of search_dblink
# cd ~/projects/dblink_ddbj/tests
suppressPackageStartupMessages(require(tibble, quietly = T))
suppressPackageStartupMessages(require(gt, quietly = T))
suppressPackageStartupMessages(require(dplyr, quietly = T, exclude = c("filter","lag")))
suppressPackageStartupMessages (require(tidyverse, quietly = T, mask.ok = list(dplyr = TRUE, stats = TRUE)))
make_html <- function() {
  if (file.exists("temp_dblink_ddbj/trad_bioproject2dblink.csv") || file.exists("temp_dblink_ddbj/trad_biosample2dblink.csv") || file.exists("temp_dblink_ddbj/trad_drr2dblink.csv") || file.exists("temp_dblink_ddbj/trad_accession2dblink.csv") ){
    system("cat temp_dblink_ddbj/trad_*2dblink.csv > temp_dblink_ddbj/all_trad.csv")
    test_all_trad <- as.numeric (system("wc -l temp_dblink_ddbj/all_trad.csv | cut -f1 -d' ' ", intern=T))
    if (test_all_trad > 0) {
      tb <- unique(read.csv("temp_dblink_ddbj/all_trad.csv", header=F))
      colnames(tb) <- c("accession","bioproject","biosample","db_name","taxon_id","status","count")
      len_tb <- dim(tb)[1]
      if(len_tb > 0){
       st <- unique(tb[,c("accession","status","count")])
       st$st_count <- paste(st$status,st$count,sep=":")
       st <- st[, c("accession","st_count")]
       st$num <- 1
       agg <- aggregate(st$num,by = list(accession=st$accession),FUN = sum)
       colnames(agg)[2] <- "num"
       one <- agg[agg$num == 1,]
       st_one <- merge(st, one, by="accession")
       st_one <- st_one[,c("accession","st_count")]
       filt <- agg[agg$num > 1,]
       len_filt <- dim(filt)[1]
       if(len_filt > 0){
         i <- 1
         for(i in 1:len_filt){
           acc <- filt[i,"accession"]
           temp <- st[st$accession == acc, "st_count"]
           f_st <- paste(temp, collapse = ",")
           line2add <- data.frame(accession = acc, st_count = f_st)
           st <- rbind(st_one, line2add)
         }
       }
       tb <- unique(subset(tb, select=-c(status,count)))
       
       bs_drr <- unique(tb[,c("accession", "biosample")])
       bs <- bs_drr[grep("SAM", bs_drr$biosample),]
       drr <- bs_drr[grep("RR", bs_drr$biosample),]
       # biosample
       len_bs <- dim(bs)[1]
       if(len_bs > 0){
         bs$num <- 1
         agg <- aggregate(bs$num,by = list(accession=bs$accession),FUN = sum)
         colnames(agg)[2] <- "num"
         one_bs <- agg[agg$num == 1,]
         bs_num <- merge(bs, one_bs, by="accession")
         bs_num <- bs_num[,c("accession","biosample")]
         filt_bs <- agg[agg$num > 1,]
         len_filt_bs <- length(filt_bs$accession)
         i <- 1
         bs <- subset(bs, select=-c(num))
         if(len_filt_bs > 0){ # bug: check if there are biosample
           for(i in 1:len_filt_bs){
             acc <- filt_bs[i,"accession"]
             temp <- bs[bs$accession == acc, "biosample"]
             f_bs <- paste(temp, collapse = ",")
             line2add <- data.frame(accession = acc, biosample = f_bs)
             bs_num <- rbind(bs_num, line2add)
           }
         }
         tb <- unique(subset(tb, select=-c(biosample)))
         tb <- merge(tb, st, by="accession", all.x=T)
         tb <- merge(tb, bs_num, by="accession", all.x=T)
       } else {
         tb <- unique(merge(tb, st, by="accession", all.x=T))
         #tb <- unique(subset(tb, select=-c(num)))
       }
       # drr
       len_drr <- dim(drr)[1]
       if(len_drr > 0){
         drr$num <- 1
         agg <- aggregate(drr$num,by = list(accession=drr$accession),FUN = sum)
         colnames(agg)[2] <- "num"
         one_drr <- agg[agg$num == 1,]
         test_one_drr <- dim(one_drr)[1]
         if(test_one_drr > 0){
           drr_num <- merge(drr, one_drr, by="accession")
           drr_num <- drr_num[,c("accession","biosample")]
         } else {
           drr_num <- data.frame(accession=character(), biosample=character(), stringsAsFactors=FALSE)
         }
         filt_drr <- agg[agg$num > 1,]
         len_filt_drr <- length(filt_drr$accession)
         if(len_filt_drr > 0){
           i <- 1
           drr <- subset(drr, select=-c(num))
           for(i in 1:len_filt_drr){
             acc <- filt_drr[i,"accession"]
             temp <- drr[drr$accession == acc, "biosample"]
             f_drr <- paste(temp, collapse = ",")
             line2add <- data.frame(accession = acc, biosample = f_drr)
             drr_num <- rbind(drr_num, line2add)
           }
         }
         colnames(drr_num)[2] <- "DRR"
         tb <- merge(tb, drr_num, by="accession", all.x=T)
       }
       
       tb$link <- paste("https://www.ncbi.nlm.nih.gov/search/all/?term", tb$accession, sep="=")
       tb[grep("private", tb$st_count),'link'] <- NA
       tb <- as_tibble(tb)
       colnames(tb)[colnames(tb) == "st_count"] <- "status:count"
       gp <-  tb %>%
         dplyr::group_by(bioproject) %>%
         mutate(
             link = map(link, ~ htmltools::a(href = .x, "external_link")),
             link = map(link, ~ gt::html(as.character(.x)))) %>%
         gt(rowname_col = "accession")
         gtsave(gp, "out_dblink_ddbj/trad_dblink.html")
      }
    }
  }
  if (file.exists("temp_dblink_ddbj/trace_bioproject2dblink.csv") || file.exists("temp_dblink_ddbj/trace_biosample2dblink.csv") || file.exists("temp_dblink_ddbj/trace_drr2dblink.csv") ){
    system("cat temp_dblink_ddbj/trace_*2dblink.csv > temp_dblink_ddbj/all_trace.csv")
    test_all_trace <- as.numeric (system("wc -l temp_dblink_ddbj/all_trace.csv | cut -f1 -d' ' ", intern=T))
    if(test_all_trace > 0){
      trace <- unique(read.csv("temp_dblink_ddbj/all_trace.csv", header=F))
      colnames(trace) <- c("bs_submitter","biosample","bs_status","taxon_id","bs_locus_tag","bioproject","bp_submitter","bp_status","project_type","bp_locus_tag","drr")
      trace$link <- paste("https://www.ncbi.nlm.nih.gov/biosample", trace$biosample, sep="/")
      trace[trace$trace_bs_status == "private",'link'] <- NA
      len_trace <- dim(trace)[1]
      if(len_trace > 0){
        trace <- as_tibble(trace)
        gp <-  trace %>%
          dplyr::group_by(bioproject) %>%
          dplyr::arrange(bioproject, biosample) %>%
          mutate(
              link = map(link, ~ htmltools::a(href = .x, "external_link")),
              link = map(link, ~ gt::html(as.character(.x)))) %>%
          gt(rowname_col = "biosample")
          gtsave(gp, "out_dblink_ddbj/trace_dblink.html")
      }
    }
  }
  if (file.exists("temp_dblink_ddbj/mtb2dblink.csv") ){
    mtb <- unique(read.csv("temp_dblink_ddbj/mtb2dblink.csv", header=F))
    colnames(mtb) <- c("mtb_id","bioproject","biosample","mtb_status","taxon_id","trace_bp_submitter","trace_bp_status","project_type","trace_bs_submitter","trace_bs_status","locus_tag","DRR")
    mtb$link <- paste("https://www.ncbi.nlm.nih.gov/biosample", mtb$biosample, sep="/")
    mtb[mtb$trace_bs_status == "private",'link'] <- NA
    len_mtb <- dim(mtb)[1]
    if(len_mtb > 0){
      mtb <- as_tibble(mtb)
      mtb[is.na(mtb$locus_tag),]$locus_tag <- ""
      mtb[is.na(mtb$DRR),]$DRR <- ""
      gp <-  mtb %>%
        dplyr::group_by(mtb_id) %>%
        dplyr::arrange(bioproject, biosample) %>%
        mutate(
            link = map(link, ~ htmltools::a(href = .x, "external_link")),
            link = map(link, ~ gt::html(as.character(.x)))) %>%
        gt(rowname_col = "biosample")
        gtsave(gp, "out_dblink_ddbj/mtb_dblink.html")
    }
  }
  if (file.exists("temp_dblink_ddbj/gea2dblink.csv") ){
    gea <- unique(read.csv("temp_dblink_ddbj/gea2dblink.csv", header=F))
    colnames(gea) <- c("gea","bioproject","biosample","gea_status","trace_taxon","seq_accession","trace_bs_submitter","trace_bs_status","bs_locus_tag","trace_drr")
    len_gea <- dim(gea)[1]
    gea_ids <- unique(gea$gea)
    len_gea_ids <- length(gea_ids)
    if(len_gea > 0){
      j <- 1
      final_gea <- data.frame(gea=character(), bioproject=character(), biosample=character(), trace_taxon=character(), seq_accession=character(), trace_bs_submitter=character(), trace_bs_status=character(), bs_locus_tag=character(), trace_drr=character(), stringsAsFactors=FALSE)
      for (j in 1:len_gea_ids){
        geaj <- gea_ids[j]
        temp_geabp <- gea[gea$gea == geaj,]
        bps <- unique(temp_geabp$bioproject)
        len_bps <- length(bps)
        k <- 1
        for (k in 1:len_bps){
          bpsk <- bps[k]
          temp_gea <- temp_geabp[temp_geabp$bioproject == bpsk,]
          bs <- sort(unique(temp_gea$biosample))
          bs <- paste(bs, collapse = ",")
          trace_taxon <- unique(temp_gea$trace_taxon)
          trace_taxon <- paste(trace_taxon, collapse = ",")
          seq_accession <- sort(unique(temp_gea$seq_accession))
          seq_accession <- paste(seq_accession, collapse = ",")
          trace_bs_submitter <- unique(temp_gea$trace_bs_submitter)
          trace_bs_submitter <- paste(trace_bs_submitter, collapse = ",")
          trace_bs_status <- unique(temp_gea$trace_bs_status)
          trace_bs_status <- paste(trace_bs_status, collapse = ",")
          bs_locus_tag <- unique(temp_gea$bs_locus_tag)
          bs_locus_tag <- paste(bs_locus_tag, collapse = ",")
          trace_drr <- sort(unique(temp_gea$trace_drr))
          trace_drr <- paste(trace_drr, collapse = ",")
          gea_status <- sort(unique(temp_gea$gea_status))
          gea_status <- paste(gea_status, collapse = ",")
          line2add <- data.frame(gea = geaj, bioproject = bps, biosample = bs, gea_status = gea_status, trace_taxon = trace_taxon, seq_accession = seq_accession, trace_bs_submitter = trace_bs_submitter, trace_bs_status = trace_bs_status, bs_locus_tag = bs_locus_tag, trace_drr = trace_drr)
          line2add$link <- paste("https://www.ncbi.nlm.nih.gov/bioproject", line2add$bioproject, sep="/")
          line2add[line2add$gea_status == "private",'link'] <- NA
          final_gea <- rbind(final_gea, line2add)
        }
      }
    }
    len_final_gea <- dim(final_gea)[1]
    if(len_final_gea > 0){
      final_gea <- as_tibble(final_gea)
      gp <-  final_gea %>%
        dplyr::group_by(gea) %>%
        dplyr::arrange(gea, bioproject) %>%
        mutate(
            link = map(link, ~ htmltools::a(href = .x, "external_link")),
            link = map(link, ~ gt::html(as.character(.x)))) %>%
        gt(rowname_col = "bioproject")
        gtsave(gp, "out_dblink_ddbj/gea_dblink.html")
    }
  }
}
make_html()
