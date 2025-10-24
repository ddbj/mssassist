###
# find correlation primary accession to secondary accession 
###
suppressMessages(require(data.table))
# at102
filename <- "temp/at102_rel2nd_accession.txt"
if (file.exists(filename)) {
    dt <- fread(filename, header=F, sep=",")
    colnames(dt) <- c("ac_id1","accession","df_status1")
    pattern <- "B[A-Z][A-Z][A-Z]"
    # create a new status to isolate this cases from the bunch
    dt[grep(pattern, dt$accession),]$df_status1 <- 2052
    # merge by accession
    has_sec <- dt[dt$df_status1 == 1049,]
    sec <- dt[dt$df_status1 == 1052,]
    colnames(sec) <- c("ac_id2","accession","df_status2")
    partial1 <- merge(has_sec, sec, by="accession" , all =T)
    partial1_current <- partial1[is.na(partial1$ac_id2), c("accession", "ac_id1", "df_status1")]
    partial1_obsolete <- partial1[!is.na(partial1$ac_id2), c("accession", "ac_id1", "df_status2") ]
    colnames(partial1_obsolete) <- c("accession2","ac_id1","df_status2")
    partial1 <- merge(partial1_current, partial1_obsolete, by="ac_id1")
    # merge by ac_id
    secB <- dt[dt$df_status1 == 2052,]
    colnames(secB) <- c("ac_id1","accession2","df_status2")
    partial2 <- merge(has_sec, secB, by="ac_id1")
    # versions: accession == current; accession2 == obsolete
    final <- rbind(partial1, partial2)
    final$df_status2 <- 1052
    final1 <- final[, c("accession", "accession2")]
    # fwrite(final1, "temp/at102_table_accession_current2obsolete.tsv", row.names=F, col.names=F, quote=F, sep="\t")
    rm(final, partial1, partial1_current, partial1_obsolete, partial2, secB, sec, has_sec, dt)
} else {
    message=paste("file", filename, "do not exist", sep=" ")
    print(message)
}
# at101
filename <- "temp/at101_rel2nd_accession.txt"
if (file.exists(filename)) {
    dt <- fread(filename, header=F, sep=",")
    colnames(dt) <- c("ac_id1","accession","df_status1")
    # merge by accession
    has_sec <- dt[dt$df_status1 == 1049,]
    sec <- dt[dt$df_status1 == 1052,]
    colnames(sec) <- c("ac_id2","accession","df_status2")
    partial1 <- merge(has_sec, sec, by="accession" , all =T)
    partial1_current <- partial1[is.na(partial1$ac_id2), c("accession", "ac_id1", "df_status1")]
    partial1_obsolete <- partial1[!is.na(partial1$ac_id2), c("accession", "ac_id1", "df_status2") ]
    colnames(partial1_obsolete) <- c("accession2","ac_id1","df_status2")
    final <- merge(partial1_current, partial1_obsolete, by="ac_id1")
    # versions: accession == current; accession2 == obsolete
    final2 <- final[, c("accession", "accession2")]
    # fwrite(final2, "temp/at101_table_accession_current2obsolete.tsv", row.names=F, col.names=F, quote=F, sep="\t")
    rm(final, partial1, partial1_current, partial1_obsolete, sec, has_sec, dt)
} else {
    message=paste("file", filename, "do not exist", sep=" ")
    print(message)
}
final <- rbind(final1, final2)
fwrite(final, "../../dblink_ddbj_standby/tsunami/table_accession_current2obsolete.csv", row.names=F, col.names=F, quote=F, sep=",")
# create table secondary_accession (accession, type[pri:primary,sec:secondary])
primary <- as.data.frame(unique(final$accession))
colnames(primary) <- "accession"
primary$type <- "pri"
secondary <- as.data.frame(unique(final$accession2))
colnames(secondary) <- "accession"
secondary$type <- "sec"
accession_type <- rbind(primary, secondary)
fwrite(accession_type, "../../dblink_ddbj_standby/tsunami/table_accession_type.csv", row.names=F, col.names=F, quote=F, sep=",")