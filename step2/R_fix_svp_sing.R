suppressMessages(require(data.table, quietly = T))
suppressMessages(require(stringr, quietly = T))

R_fix_svp <- function() {
  # read output of SVP
  rvalidator <- fread("/data/Rfixed/warnings_SVP.tsv",header=F,sep="\t", fill=TRUE )
  colnames(rvalidator) <- c('source', 'level', 'id', 'biosample_id', 'message', 'location')
  rvalidator_sources <- unique(rvalidator$source)
  len_rvalidator_source <- length(rvalidator_sources)

  for(l in 1:len_rvalidator_source) {
    ann_file2fix <- rvalidator_sources[l]
    ann_file2fix
    rvalidator_source_id <- rvalidator[rvalidator$source == ann_file2fix, ]
    ann <- fread(ann_file2fix, header = F, sep = "\t", fill=TRUE)[, 1:5] # add fill=T
    colnames(ann) <- c("Entry", "Feature", "Location", "Qualifier", "Value")
    len_ann <- dim(ann)[1]
    # R_fix_rrna: fix location of partial rRNA
    len_rvalidator_rrna <- length(grep("SVP0100", rvalidator_source_id$id))
    if (len_rvalidator_rrna > 0) {
      for (m in 1:len_rvalidator_rrna) {
        data2fix <- rvalidator_source_id$location[m]
        strand <- length(grep("complement",data2fix))
        if (strand == 1) {
          fixed_format <- sub("[(]", "(<", data2fix)
          temp_format <- as.data.frame(str_split(fixed_format, "[.]", simplify = T))
          fixed_format <- paste(temp_format$V1, "..>", temp_format$V3, sep = "")
          ann[ann$Location == data2fix, "Location"]$Location <- fixed_format
        }else if (strand == 0) {
          fixed_format <- paste("<", data2fix, sep="")
          temp_format <- as.data.frame(str_split(fixed_format, "[.]", simplify = T))
          fixed_format <- paste(temp_format$V1, "..>", temp_format$V3, sep = "")
          ann[ann$Location == data2fix, "Location"]$Location <- fixed_format
        }
      }
    }
    # filename_ann <- paste("/data/Rfixed",ann_file2fix, sep="/")
    write.table(ann, ann_file2fix, row.names = F, col.names = F, quote = F, sep = "\t")
  }
}

R_fix_svp()
