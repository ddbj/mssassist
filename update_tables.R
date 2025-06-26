library(data.table)
library(stringr)
setwd("/home/w3const/mssassist/tables")
bp <- fread("bioproject.csv",header=F,sep=",")
bp$temp <- formatC(bp$V3, width = 5, format = "d", flag = "0")
bp$prjdb <- paste(bp$V2, bp$temp, sep="")
bp <- bp[,c('V1','prjdb')]
colnames(bp)[1] <- 'psub'
write.table(bp, "bioproject_psub.csv", col.names = T, row.names = F, quote = F, sep = ",")
# table smp_id to drx
drx <- fread("drmdb.drx.csv",header=F,sep=",")
ssub <- drx[drx$V1 == "SSUB",]
ssub$temp <- formatC(ssub$V4, width = 6, format = "d", flag = "0")
ssub$drx <- paste(ssub$V3, ssub$temp, sep="")
ssub <- ssub[,c('V2','drx')]
colnames(ssub)[1] <- 'smp_id' # not bug: it seems like ssub number but it is indeed smp_id.
write.table(ssub, "drmdb.drx_ssub.csv", col.names = T, row.names = F, quote = F, sep = ",")
# psub
psub <- drx[drx$V1 == "PSUB",]
psub$temp <- formatC(psub$V4, width = 6, format = "d", flag = "0")
psub$drx <- paste(psub$V3, psub$temp, sep="")
psub <- psub[,c('V2','drx')]
colnames(psub)[1] <- 'psub'
write.table(psub, "drmdb.drx_psub.csv", col.names = T, row.names = F, quote = F, sep = ",")
# drr
drr <- fread("drmdb.drr.csv",header=F,sep=",")
psub <- drr[drr$V1 == "PSUB",]
psub$temp <- formatC(psub$V4, width = 6, format = "d", flag = "0")
psub$drr <- paste(psub$V3, psub$temp, sep="")
psub <- psub[,c('V2','drr')]
colnames(psub)[1] <- 'smp_id'
write.table(psub, "drmdb.drr_smp.csv", col.names = T, row.names = F, quote = F, sep = ",")
# bioproject id
directory <- "." # ddbjs1
# biosample consider status_id
filename <- paste(directory, "biosample.biosample_summary2.csv", sep = "/")
bs_temp <- fread(filename, header = F, sep = "|")
colnames(bs_temp) <- c("submission_id", "accession_id", "smp_id", "email", "first_name", "last_name", "entity_status")
filename <- paste(directory, "biosample.sample.status_id.csv", sep = "/")
bs_status <- fread(filename, header = F, sep = "|")
colnames(bs_status) <- c("smp_id", "status_id")
bs <- merge(bs_temp, bs_status, by="smp_id") # removing accession_id == ""
bs$contact <- paste(bs$first_name, bs$last_name, sep=" ")
bs$ab <- substr(bs$first_name, 1, 1)
bs$ab <- paste(bs$ab, ".", sep="")
bs$ab_name <- paste(bs$last_name,bs$ab, sep=",")
# "smp_id", "email", "contact", "ab_name"
contact <- unique(bs[, c("accession_id", "email", "contact", "ab_name")])
write.table(contact, "biosample.summary_contact.csv", col.names = F, row.names = F, quote = F, sep = "|")
# "submission_id", "accession_id", "smp_id"
bs <- unique(bs[, c("submission_id", "accession_id", "smp_id")])
write.table(bs, "clean2_biosample.biosample_summary.csv", col.names = F, row.names = F, quote = F, sep = "|")
bs <- as.data.frame(bs)
filename <- paste(directory, "bp2smp_id.csv", sep = "/")
bp2smp_id <- fread(filename, header = F, sep = "\t")
colnames(bp2smp_id) <- c("prjdb", "smp_id")
bs$smp_id <- as.numeric(bs$smp_id)
bs2bp <- merge(bs, bp2smp_id, by="smp_id")
bs2bp <- bs2bp[bs2bp$accession_id != "", c("accession_id", "prjdb")]
write.table(bs2bp, "bs_id.bp_id.csv", col.names = T, row.names = F, quote = F, sep="\t")
# bs2bp_via_locus_tag; prepare this tables on update_tables; table 2/3
# locus_tag
filename <- paste(directory, "clean_biosample.attribute_name_locus_tag_prefix.csv", sep = "/")
locus_tag <- fread(filename, header = F, sep = "|")[, 3:4] # optimize this table
locus_tag <- as.data.frame(locus_tag)
colnames(locus_tag) <- c("locus_tag", "smp_id")
bs_locus_tag_all <- merge(bs, locus_tag, by = "smp_id")
filename <- paste(directory, "clean_bioproject.submission_data_locus_tag.csv", sep = "/")
bp2locus_tag <- fread(filename, header = F, sep = "|")
colnames(bp2locus_tag) <- c("psub","locus_tag")
bp2bs_via_locus_tag_prefix <- merge(bp2locus_tag, bs_locus_tag_all, by="locus_tag")
filename <- paste(directory, "bioproject.psub2prjd.csv", sep = "/")
psub2bp <- fread(filename, header = F, sep = "\t")
colnames(psub2bp) <- c("psub", "prjdb", "db_type")
bp2bs_via_locus_tag_prefix <- merge(bp2bs_via_locus_tag_prefix, psub2bp, by="psub")
bp2bs_via_locus_tag_prefix <- bp2bs_via_locus_tag_prefix[, c("accession_id", "prjdb")] # removing db_type (primary or umbrella)
write.table(bp2bs_via_locus_tag_prefix, "bp2bs_via_locus_tag_prefix.csv", col.names = T, row.names = F, quote = F, sep = "\t")
# smp2psub via drr; table 3/3
filename <- paste(directory, "drmdb.smp2drr.csv", sep = "/")
smp2drr <- as.data.frame(fread(filename, header = F, sep = "\t"))
colnames(smp2drr) <- c( "smp_id", "drr")
filename <- paste(directory, "drmdb.psub2drr.csv", sep = "/")
drr2psub <- as.data.frame(fread(filename, header = F, sep = "\t"))
colnames(drr2psub) <- c( "psub", "drr")
bp2bs_via_drr <- merge(drr2psub, smp2drr, by = "drr")
bug_drr_table <- bp2bs_via_drr[grep("PRJDA", bp2bs_via_drr$psub),]
colnames(bug_drr_table)[colnames(bug_drr_table) == "psub"] <- "prjdb"
bp2bs_via_drr <- merge(bp2bs_via_drr,bp ,by = "psub")
bp2bs_via_drr <- bp2bs_via_drr[, c("drr", "prjdb", "smp_id")]
bp2bs_via_drr <- rbind(bug_drr_table, bp2bs_via_drr)
# remove 0 before number on bioproject_id
bp2bs_via_drr$numb <- as.numeric(gsub("[a-zA-Z]", "", bp2bs_via_drr$prjdb))
bp2bs_via_drr$temp <- substr(bp2bs_via_drr$prjdb, 1, 5)
bp2bs_via_drr$prjdb <- paste(bp2bs_via_drr$temp, bp2bs_via_drr$numb, sep = "")
bp2bs_via_drr <- bp2bs_via_drr[, c("drr", "prjdb", "smp_id")]
write.table(bp2bs_via_drr, "bp2bs_via_drr.csv", col.names = T, row.names = F, quote = F, sep = "\t")
# DRR
bs$smp_id <- as.character(bs$smp_id)
bs_smp2drr <- merge(bs, smp2drr, by="smp_id")
bs_smp2drr <- bs_smp2drr[, c('accession_id', 'drr')]
bs_smp2drr$drr <- as.numeric(sub("DRR","", bs_smp2drr$drr))
bs_smp2drr$temp <- formatC(bs_smp2drr$drr, width = 6, format = "d", flag = "0")
bs_smp2drr$drr <- paste("DRR", bs_smp2drr$temp, sep="")
bs_smp2drr <- bs_smp2drr[, c('accession_id', 'drr')]
write.table(bs_smp2drr, "bs_smp2drr.csv", col.names = F, row.names = F, quote = F, sep = "\t")
