require(fedmatch, quietly = T)
require(data.table, quietly = T)
filename <- read.table("/data/temp_svp/temp_ann_filename.temp", header=F)
database <- fread("/srv/clean_taxid2scientific_name.tsv", header=F, sep="\t")
organism_ann <- fread("/data/temp_svp/organism_ann.txt", header=F, sep="\t")
colnames(database) <- "taxdump"
colnames(organism_ann) <- "organism"
all_wrong_org <- as.data.frame(setdiff(organism_ann$organism, database$taxdump))
colnames(all_wrong_org) <- "ann_file"
len_all_wrong_org <- dim(all_wrong_org)[1]
if(len_all_wrong_org > 0){
  len_database <- dim(database)[1]
  database$unique_key_2 <- 1:len_database
  all_wrong_org$unique_key_1 <- 1:len_all_wrong_org
  fuzzy_result <- merge_plus(data1 = all_wrong_org, data2 = database, by.x = "ann_file", by.y = "taxdump", match_type = "fuzzy", unique_key_1 = "unique_key_1", unique_key_2 = "unique_key_2",)
  all_result <- fuzzy_result$matches[, 3:4]
  len_all_result <- dim(all_result)[1]
  if( len_all_result > 0 ){
    all_wrong_org <- merge(all_result, all_wrong_org, by="ann_file", all.y=T)
    all_wrong_org[is.na(all_wrong_org$taxdump),]$taxdump <- "suggestion not found"
    all_wrong_org$source <- filename$V1
    all_wrong_org <- all_wrong_org[,c("source", "taxdump", "ann_file")]
  } else {
    all_wrong_org$source <- filename$V1
    all_wrong_org$taxdump <- "suggestion not found"
    all_wrong_org <- all_wrong_org[,c("source", "taxdump", "ann_file")] 
  }
  fwrite(all_wrong_org, "/data/temp_svp/temp_organism_warning_org_taxdump.txt", row.names=F, col.names=F, quote=F, sep="\t")
}

###
# database <- fread("/home/andreaghelfi/backup_data_gw/scripts/tables/clean_taxid2scientific_name.tsv", header=F, sep="\t")
# organism_ann <- fread("temp_svp/organism_ann.txt", header=F, sep="\t")
# filename <- read.table("temp_svp/temp_ann_filename.temp", header=F)

