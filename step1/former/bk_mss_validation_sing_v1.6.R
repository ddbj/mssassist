################################
# Developed by Andrea Ghelfi
# 2022.5.27
################################
require(data.table, quietly = T)
require(stringr, quietly = T)

directory <- "/srv"
scripts_dir <- "/mnt"
# testonly
# directory <- "~/scripts/tables"
# directory <- "~/backup_data_gw/scripts/tables/"

# biosample
filename <- paste(directory, "clean2_biosample.biosample_summary.csv", sep = "/")
bs <- fread(filename, header = F, sep = "|") # optimize this table
colnames(bs) <- c("submission_id", "accession_id" , "smp_id")
bs <- as.data.frame(bs)
# country
filename <- paste(directory, "clean_biosample.attribute_name_geo_loc_name.csv", sep = "/")
geo_loc_name <- fread(filename, header = F, sep = "|") # optimize this table
geo_loc_name <- as.data.frame(geo_loc_name[,3:4])
colnames(geo_loc_name) <- c("geo_loc_name", "smp_id")
# locus_tag
filename <- paste(directory, "clean_biosample.attribute_name_locus_tag_prefix.csv", sep = "/")
locus_tag <- fread(filename, header = F, sep = "|") # optimize this table
locus_tag <- as.data.frame(locus_tag[,3:4])
colnames(locus_tag) <- c("locus_tag", "smp_id")
# organism name
filename <- paste(directory, "biosample.organism.csv", sep = "/")
org <- fread(filename, header=F, sep="|")[,2:3] # optimize this table
colnames(org) <- c("organism", "smp_id")
# strain name
filename <- paste(directory, "clean_biosample.strain.csv", sep = "/")
strain <- as.data.frame(fread(filename, header=F, sep="|"))[,2:3] # optimize this table
colnames(strain) <- c("strain", "smp_id")
strain$smp_id <- as.character(strain$smp_id)
# isolate name
filename <- paste(directory, "clean_biosample.isolate.csv", sep = "/")
isolate <- as.data.frame(fread(filename, header=F, sep="|"))[,2:3] # optimize this table
colnames(isolate) <- c("isolate", "smp_id")
isolate$smp_id <- as.character(isolate$smp_id)
# cultivar name
filename <- paste(directory, "clean_biosample.cultivar.csv", sep = "/")
cultivar <- as.data.frame(fread(filename, header=F, sep="|"))[,2:3] # optimize this table
colnames(cultivar) <- c("cultivar", "smp_id")
cultivar$smp_id <- as.character(cultivar$smp_id)
# collection_date
filename <- paste(directory, "clean_biosample.collection_date.csv", sep = "/")
collection_date <- as.data.frame(fread(filename, header = F, sep = "|"))
colnames(collection_date) <- c("collection_date", "smp_id")
collection_date$smp_id <- as.character(collection_date$smp_id)
# species lower ranks; update dialy from taxonomy dump file, then copy to gw
# filename <- paste(directory, "lower_ranks_list.tsv", sep = "/")
# lower_ranks <- fread(filename, header = T, sep = "\t")
# filename <- paste(directory, "strain_from_sp_list.list", sep = "/")
# strainfromsplist <- fread(filename, header = F, sep = "\t")
# colnames(strainfromsplist) <- c("sp_taxid", "sp_name", "strain_name")
# host name
filename <- paste(directory, "clean_biosample.attribute_name_host.csv", sep = "/")
hostname <- as.data.frame(fread(filename, header = F, sep = "|")[,2:3])
colnames(hostname) <- c("hostname", "smp_id")
# status_id
filename <- paste(directory, "biosample.sample.status_id.csv", sep = "/")
status_id <- as.data.frame(fread(filename, header = F, sep = "|"))
colnames(status_id) <- c( "smp_id", "status_id")
# bioproject id # table optimized; attention not all bioproject are in this table, also check drmdb.drr.csv (drmdb.drr.csv, then bioproject.csv)
filename <- paste(directory, "bs_id.bp_id.csv", sep = "/") # table 1/3 (include two other methods to correlate bs_id with bp_id, using attribute)
bs2bp <- fread(filename, header = T, sep = "\t") # change variable bs2bp_via_attribute
filename <- paste(directory, "bp2bs_via_locus_tag_prefix.csv", sep = "/") # table 2/3
bp2bs_via_locus_tag_prefix <- fread(filename, header = T, sep = "\t") # change variable bs2bp_via_locus_tag_prefix
filename <- paste(directory, "bp2bs_via_drr.csv", sep = "/") # table 3/3
bp2bs_via_drr <- fread(filename, header = T, sep = "\t") # change variable bp2bs_via_drr
# isolate_source
filename <- paste(directory, "biosample.isolation_source.csv", sep = "/")
isolation_source <- as.data.frame(fread(filename, header = F, sep = "|"))
colnames(isolation_source) <- c("isolation_source", "smp_id")
##
ddbj_mss_validation <- function() {
  line_lines_input_ids <- " wc -l /data/temp_svp/input_ids.txt | cut -f1 -d\" \" "
  lines_input_ids <- as.numeric(system(line_lines_input_ids, intern = T))
  if(lines_input_ids > 0) {
    input_ids <- read.table("temp_svp/input_ids.txt", header=F)
    colnames(input_ids) <- "source"
    input_ids$source <- paste("/data/Rfixed/", input_ids$source,".ann",sep="") # added Rfixed here v1.0
    len_input_ids <- length(input_ids$source)
    final_log_file <- c()
    final_feature_location <- c()
    l <- 1
    for(l in 1:len_input_ids) {
      log_file <- data.frame(matrix(ncol = 33, nrow = 1))
      # add geo_loc_name and geo_loc_name_ann mss_validation_sing_v1.6
      colnames(log_file) <- c('source', 'biosample_id_ann', 'smp_id', 'bioproject', 'bioproject_ann', 'drr', 'organism', 'organism_ann', 'isolate', 'isolate_ann', 'strain', 'strain_ann', 'cultivar', 'cultivar_ann', 'locus_tag', 'locus_tag_ann', 'country', 'country_source_ann', 'collection_date', 'collection_date_ann', 'overlap', 'predicted_subsp', 'predicted_subsp_value', 'predicted_subsp_value_ann', 'predicted_qualifier', 'predicted_qualifier_value', 'predicted_qualifier_value_ann', 'host', 'host_ann', 'isolation_source', 'isolation_source_ann', 'geo_loc_name', 'geo_loc_name_ann')
      ann_file2fix <- input_ids$source[l]
      ann <- fread(ann_file2fix, header=F, sep="\t", fill=T)[,1:5]
      colnames(ann) <- c("Entry", "Feature", "Location", "Qualifier", "Value")
      len_ann <- dim(ann)[1]
      log_file$source <- ann_file2fix
      ann_biosample_id <- ann[ann$Qualifier == "biosample", "Value" ]$Value
      ann_biosample_id <- ann_biosample_id[ann_biosample_id != ""]
      len_ann_biosample_id <- length(ann_biosample_id)
      if(len_ann_biosample_id > 0) {
        log_file$biosample_id_ann <- ann_biosample_id
        sample_smp_id <- bs[grep(ann_biosample_id, bs$accession_id),]
        sample_smp_id <- merge(sample_smp_id, status_id, by="smp_id")
        sample_smp_id <- sample_smp_id$smp_id
        length_sample_smp_id <- length(sample_smp_id)
        # bioproject
        ann_bioproject_id <- ann[ann$Qualifier == "project", "Value"]$Value
        len_ann_bioproject_id <- length(ann_bioproject_id)
        meta_prjdb <- bs2bp[bs2bp$accession_id == ann_biosample_id, ]$prjdb # table 1/3
        len_meta_prjdb <- length(meta_prjdb)
        if(len_meta_prjdb == 0 & length_sample_smp_id == 0){ # v1.4
          meta_prjdb <- bp2bs_via_locus_tag_prefix[bp2bs_via_locus_tag_prefix$accession_id == ann_biosample_id, ]$prjdb # table 2/3
          len_meta_prjdb <- length(meta_prjdb)
        }
        if(len_meta_prjdb == 0 & length_sample_smp_id == 1){
          meta_prjdb <- bp2bs_via_drr[bp2bs_via_drr$smp_id == sample_smp_id, ]$prjdb # table 3/3
          len_meta_prjdb <- length(meta_prjdb)
        }
        if(len_meta_prjdb == 1 & len_ann_bioproject_id == 1) { # I am assuming that there are only one bioproject_id per biosample_id
          log_file$bioproject <- meta_prjdb
          log_file$bioproject_ann <- ann_bioproject_id
        } else if(len_meta_prjdb == 0 & len_ann_bioproject_id == 1) {
          log_file$bioproject <- "Missing_value"
          log_file$bioproject_ann <- ann_bioproject_id
        } else if(len_meta_prjdb == 1 & len_ann_bioproject_id == 0) {
          log_file$bioproject <- meta_prjdb
          log_file$bioproject_ann <- NA
        }
        # detect overlap (reference: JP0176) # v1.5 added new method to find Entry ID
        # awk -F"\t" -v OFS="\t" '{if($1 != "") {entry = $1}; if($2 == "assembly_gap") {print entry, $2, $3}}' Rfixed/SAMD00248959.ann 
        # awk -F"\t" -v OFS="\t" '{if($1 != "") {entry = $1}; if($2 == "CDS" || $2 == "mRNA") {print entry, $2, $3}}' Rfixed/SAMD00248959.ann 
        line_feature_assembly_gap <- "awk -F\"\t\" -v OFS=\"\t\" '{if($1 != \"\") {entry = $1}; if($2 == \"assembly_gap\") {print entry, $2, $3}}' FILE2FIX > /data/temp_autofix/feature_assembly_gap.tsv "
        line_feature_assembly_gap <- sub("FILE2FIX", ann_file2fix, line_feature_assembly_gap)
        line_feature_cds <- "awk -F\"\t\" -v OFS=\"\t\" '{if($1 != \"\") {entry = $1}; if($2 == \"CDS\" || $2 == \"mRNA\") {print entry, $2, $3}}' FILE2FIX > /data/temp_autofix/feature_cds.tsv "
        line_feature_cds <- sub("FILE2FIX", ann_file2fix, line_feature_cds)
        system(line_feature_assembly_gap, intern=F)
        system(line_feature_cds, intern=F)
        line_test_feature_assembly_gap <- " wc -l /data/temp_autofix/feature_assembly_gap.tsv | cut -f1 -d\" \" "
        lines_feature_assembly_gap <- as.numeric(system(line_test_feature_assembly_gap, intern = T))
        line_test_feature_cds <- " wc -l /data/temp_autofix/feature_cds.tsv | cut -f1 -d\" \" "
        lines_feature_cds <- as.numeric(system(line_test_feature_cds, intern = T))
        if(lines_feature_assembly_gap > 0 & lines_feature_cds > 0) {
          feature_assembly_gap <- fread("/data/temp_autofix/feature_assembly_gap.tsv", header = F, sep = "\t")[,c(1, 3)]
          feature_cds <- fread("/data/temp_autofix/feature_cds.tsv", header = F, sep = "\t")[,c(1, 3)]
          colnames(feature_assembly_gap) <- c("Entry", "assembly_gap_location")
          colnames(feature_cds) <- c("Entry", "cds_location")
          feature_location <- merge(feature_cds, feature_assembly_gap, by = "Entry", allow.cartesian=TRUE) # fixed bug
          #
          feature_location$temp_cds <- sub("complement","",feature_location$cds_location)
          feature_location$temp_cds <- sub("[(]","",feature_location$temp_cds)
          feature_location$temp_cds <- sub("[)]","",feature_location$temp_cds)
          ## remove < and > signals
          feature_location$temp_cds <- sub(">","",feature_location$temp_cds)
          feature_location$temp_cds <- sub("<","",feature_location$temp_cds)
          ##
          feature_location$cds_start <- as.data.frame(str_split(feature_location$temp_cds, "[.]", simplify=T))[1]
          feature_location$cds_end <- as.data.frame(str_split(feature_location$temp_cds, "[.]", simplify=T))[3]
          feature_location$cds_start <- as.numeric(as.character(feature_location$cds_start))
          feature_location$cds_end <- as.numeric(as.character(feature_location$cds_end))
          # assembly_gap
          feature_location$gap_start <- as.data.frame(str_split(feature_location$assembly_gap_loc, "[.]", simplify=T))[1]
          feature_location$gap_end <- as.data.frame(str_split(feature_location$assembly_gap_loc, "[.]", simplify=T))[3]
          feature_location$gap_start <- as.numeric(as.character(feature_location$gap_start))
          feature_location$gap_end <- as.numeric(as.character(feature_location$gap_end))
          # find overlapped; condition 1: gap is completely within CDS (next version implement overlapping only 5' or only 3')
          bk_feature_location <- feature_location
          #
          feature_location <- feature_location[(feature_location$gap_start >= feature_location$cds_start & feature_location$gap_start <= feature_location$cds_end) & (feature_location$gap_end >= feature_location$cds_start & feature_location$gap_end <= feature_location$cds_end),]
          # test if there is line in feature_location
          len_feature_location <- dim(feature_location)[1]
          if(len_feature_location > 0) {
            feature_location$new_cds_end <- feature_location$gap_start-1
            feature_location$new_cds_start <- feature_location$gap_end+1
            feature_location$len_cds1 <- feature_location$new_cds_end - feature_location$cds_start + 1
            feature_location$len_cds2 <- feature_location$cds_end - feature_location$new_cds_start + 1
            # modification start here
            feature_location$source <- ann_file2fix
            feature_location <- feature_location[ ,c(13, 1:12)]
            final_feature_location <- rbind(final_feature_location, feature_location)
            # modification end
            feature_location$count <- 1
            # aggregate overlapping assembly_gap in the same CDS
            agg <- aggregate(feature_location$count,by = list(Entry = feature_location$Entry, cds_location = feature_location$cds_location), FUN = sum)
            colnames(agg)[3] <- "count"
            agg <- agg[order(agg$count,decreasing=T),]
            n_gap_overlaps <- agg[agg$count > 1, ]
            len_n_gap_overlaps <- dim(n_gap_overlaps)[1]
            all_message_agg <- c()
            if(len_n_gap_overlaps > 0) {
              message_agg <- paste("\nEntry [", n_gap_overlaps$Entry, "] position [", n_gap_overlaps$cds_location, "] has [", n_gap_overlaps$count, "] assembly_gaps overlapping same CDS. It will not be fixed. \n", sep="")
              write.table(agg, "/data/Rfixed/feature_location_aggregated.tsv", row.names=F, col.names=T, quote=F, sep="\t") # not append
              #cat(message_agg)
              all_message_agg <- rbind(all_message_agg, message_agg)
              write.table(all_message_agg, "/data/Rfixed/all_messages_aggregated.tsv", row.names=F, col.names=F, quote=F, sep="\t") # not append
            }
            log_file$overlap <- "detected"
          }
        }
        # smp_id
        if(length_sample_smp_id == 1) {
          log_file$smp_id <- sample_smp_id
          # fix locus_tag (TR_R0020)
          bs_locus_tag <- locus_tag[locus_tag$smp_id == sample_smp_id, "locus_tag"]
          # locus_tag on ann file
          ann_locus_tag <- head(ann[ann$Qualifier == "locus_tag",],n=1)$Value
          ann_locus_tag <- as.data.frame(str_split(ann_locus_tag, "_", simplify=T))$V1
          len_ann_locus_tag <- length(ann_locus_tag)
          len_bs_locus_tag <- length(bs_locus_tag)
          if(len_ann_locus_tag > 0 & len_bs_locus_tag > 0) {
            log_file$locus_tag <- bs_locus_tag
            log_file$locus_tag_ann <- ann_locus_tag
          } else if(len_ann_locus_tag > 0 & len_bs_locus_tag == 0) {
            log_file$locus_tag <- "Missing_value"
            log_file$locus_tag_ann <- ann_locus_tag
          } else if(len_ann_locus_tag == 0 & len_bs_locus_tag > 0) {
            log_file$locus_tag <- bs_locus_tag
            log_file$locus_tag_ann <- NA
          }
          # organism (TR_R0015)
          org_organism <- org[org$smp_id == sample_smp_id, "organism"]$organism
          # organism on ann file
          ann_organism <- head(ann[ann$Qualifier == "organism",'Value'],n=1)$Value
          len_org_organism <- length(org_organism)
          len_ann_organism <- length(ann_organism)
          if(len_ann_organism > 0 & len_org_organism > 0) {
            log_file$organism <- org_organism
            log_file$organism_ann <- ann_organism
          } else if(len_ann_organism > 0 & len_org_organism == 0) {
            log_file$organism <- "Missing_value"
            log_file$organism_ann <- ann_organism
          } else if(len_ann_organism == 0 & len_org_organism > 0) {
            log_file$organism <- org_organism
            log_file$organism_ann <- NA
          }
          # strain, isolate, cultivar
          strain_strain <- strain[strain$smp_id == sample_smp_id, ]$strain
          isolate_isolate <- isolate[isolate$smp_id == sample_smp_id, ]$isolate
          cultivar_cultivar <- cultivar[cultivar$smp_id == sample_smp_id, ]$cultivar
          ann_strain <- head(ann[ann$Qualifier == "strain", ], n=1)$Value
          ann_isolate <- head(ann[ann$Qualifier == "isolate", ], n=1)$Value
          ann_cultivar <- head(ann[ann$Qualifier == "cultivar", ], n=1)$Value
          len_strain <- length(strain_strain)
          len_isolate <- length(isolate_isolate)
          len_cultivar <- length(cultivar_cultivar)
          len_ann_strain <- length(ann_strain)
          len_ann_isolate <- length(ann_isolate)
          len_ann_cultivar <- length(ann_cultivar)
          if(len_strain == 0 & len_ann_strain == 1) {
            log_file$strain <- "Missing_value"
            log_file$strain_ann <- ann_strain
          } else if(len_strain == 1 & len_ann_strain == 1) {
            log_file$strain <- strain_strain
            log_file$strain_ann <- ann_strain
          } else if(len_strain == 1 & len_ann_strain == 0) {
            log_file$strain <- strain_strain
            log_file$strain_ann <- NA
          }
          if(len_cultivar == 0 & len_ann_cultivar == 1) {
            log_file$cultivar <- "Missing_value"
            log_file$cultivar_ann <- ann_cultivar
          } else if(len_cultivar == 1 & len_ann_cultivar == 1) {
            log_file$cultivar <- cultivar_cultivar
            log_file$cultivar_ann <- ann_cultivar
          } else if(len_cultivar == 1 & len_ann_cultivar == 0) {
            log_file$cultivar <- cultivar_cultivar
            log_file$cultivar_ann <- NA
          }
          if(len_isolate == 0 & len_ann_isolate == 1) {
            log_file$isolate <- "Missing_value"
            log_file$isolate_ann <- ann_isolate
          } else if(len_isolate == 1 & len_ann_isolate == 1) {
            log_file$isolate <- isolate_isolate
            log_file$isolate_ann <- ann_isolate
          } else if(len_isolate == 1 & len_ann_isolate == 0) {
            log_file$isolate <- isolate_isolate
            log_file$isolate_ann <- NA
          }
          # add predict subspecies level "https://www.ddbj.nig.ac.jp/ddbj/feature-table-e.html#strain"
          len_pred_subsp_level <- length(grep("subsp[.]", log_file$organism))
          predicted_subsp_value <- NA
          predicted_subsp <- NA
          predicted_qualifier_value <- NA
          predicted_qualifier <- NA
          if(len_pred_subsp_level > 0){
            predicted_subsp_value <- as.data.frame(str_split(log_file$organism, "subsp[.]", simplify=T))$V2
            predicted_subsp <- "sub_species"
            log_file$predicted_subsp <- predicted_subsp
            log_file$predicted_subsp_value <- predicted_subsp_value
            ann_subsp <- head(ann[ann$Qualifier == "sub_species", ], n=1)$Value
            len_ann_subsp <- length(ann_subsp)
            if(len_ann_subsp > 0){
              log_file$predicted_subsp_value_ann <- ann_subsp
            }
          }
          len_pred_other_sublevel <- length(grep("subst[.]|bv[.]|var[.]|str[.]|variety|subtype|cultivar|strain|biovar|serovar|chemovar", log_file$organism))
          if(len_pred_other_sublevel > 0){
            if(length(grep("bv[.]", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "bv[.]", simplify=T))$V2
              predicted_qualifier <- "biovar"
            } else if (length(grep("var[.]", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "var[.]", simplify=T))$V2
              predicted_qualifier <- "variety"
            } else if (length(grep("str[.]", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "str[.]", simplify=T))$V2
              if (length(grep("substr[.]", log_file$organism)) > 0) {
                predicted_qualifier <- "sub_strain"
              } else {
                predicted_qualifier <- "strain"
              }
            } else if (length(grep("subst[.]", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "subst[.]", simplify=T))$V2
              predicted_qualifier <- "sub_strain"
            } else if (length(grep("variety", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "variety", simplify=T))$V2
              predicted_qualifier <- "variety"
            } else if (length(grep("subtype", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "subtype", simplify=T))$V2
              predicted_qualifier <- "subtype"
            } else if (length(grep("cultivar", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "cultivar", simplify=T))$V2
              predicted_qualifier <- "cultivar"
            } else if (length(grep("strain", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "strain", simplify=T))$V2
              predicted_qualifier <- "strain"
            } else if (length(grep("biovar", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "biovar", simplify=T))$V2
              predicted_qualifier <- "biovar"
            } else if (length(grep("serovar", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "serovar", simplify=T))$V2
              predicted_qualifier <- "serovar"
            } else if (length(grep("chemovar", log_file$organism)) > 0){
              predicted_qualifier_value <- as.data.frame(str_split(log_file$organism, "chemovar", simplify=T))$V2
              predicted_qualifier <- "chemovar"
            }
            log_file$predicted_qualifier <- predicted_qualifier
            log_file$predicted_qualifier_value <- predicted_qualifier_value
            ann_other_sublevel <- head(ann[ann$Qualifier == predicted_qualifier, ], n=1)$Value
            len_ann_other_sublevel <- length(ann_other_sublevel)
            if(len_ann_other_sublevel > 0){
              log_file$predicted_qualifier_value_ann <- ann_other_sublevel
            }
          }
          if(len_pred_subsp_level > 0 & len_pred_other_sublevel > 0){
            predicted_subsp_value <- as.data.frame(str_split(predicted_subsp_value, predicted_qualifier, simplify=T))$V1
            log_file$predicted_subsp <- predicted_subsp
            log_file$predicted_subsp_value <- predicted_subsp_value
            ann_subsp <- head(ann[ann$Qualifier == "sub_species", ], n=1)$Value
            len_ann_subsp <- length(ann_subsp)
            if(len_ann_subsp > 0){
              log_file$predicted_subsp_value_ann <- ann_subsp
            }
          }
          # End of add predict subspecies level
          # collection_date
          collection_date_meta <- collection_date[collection_date$smp_id == sample_smp_id, ]$collection_date
          len_collection_date <- length(collection_date_meta)
          ann_collection_date <- head(ann[ann$Qualifier == "collection_date",'Value'],n=1)$Value
          len_ann_collection_date <- length(ann_collection_date)
          if(len_collection_date == 1 & len_ann_collection_date == 1) {
            log_file$collection_date <- collection_date_meta
            log_file$collection_date_ann <- ann_collection_date
          } else if(len_collection_date == 0 & len_ann_collection_date == 1) {
            log_file$collection_date <- "Missing_value"
            log_file$collection_date_ann <- ann_collection_date
          } else if(len_collection_date == 1 & len_ann_collection_date == 0) {
            log_file$collection_date <- collection_date_meta
            log_file$collection_date_ann <- NA
          }
          # isolation_source
          isolation_source_meta <- isolation_source[isolation_source$smp_id == sample_smp_id, ]$isolation_source
          len_isolation_source <- length(isolation_source_meta)
          ann_isolation_source <- head(ann[ann$Qualifier == "isolation_source",'Value'],n=1)$Value
          len_ann_isolation_source <- length(ann_isolation_source)
          if(len_isolation_source == 1 & len_ann_isolation_source == 1) {
            log_file$isolation_source <- isolation_source_meta
            log_file$isolation_source_ann <- ann_isolation_source
          } else if(len_isolation_source == 0 & len_ann_isolation_source == 1) {
            log_file$isolation_source <- "Missing_value"
            log_file$isolation_source_ann <- ann_isolation_source
          } else if(len_isolation_source == 1 & len_ann_isolation_source == 0) {
            log_file$isolation_source <- isolation_source_meta
            log_file$isolation_source_ann <- NA
          }
          # add country (TR_R0019)
          bs_geo_loc_name <- geo_loc_name[geo_loc_name$smp_id == sample_smp_id, "geo_loc_name"]
          len_bs_geo_loc_name <- length(bs_geo_loc_name)
          pos_feature_source <- which(ann$Feature == "source")
          len_pos_feature_source <- length(pos_feature_source)
          first_pos_feature_source <- pos_feature_source[1]
          pos_qualifier_country <- which(ann$Qualifier == "country")
          len_pos_qualifier_country <- length(pos_qualifier_country)
          if(len_pos_qualifier_country > 1) {
            first_pos_qualifier_country <- pos_qualifier_country[2]
            if(pos_qualifier_country[2] > first_pos_feature_source){
              log_file$country_source_ann <-  ann[first_pos_qualifier_country, ]$Value
            }
          }
          if(len_pos_feature_source >= len_pos_qualifier_country){
            log_file$country_source_ann <- NA
          }
          if(len_bs_geo_loc_name == 1) {
            log_file$country <- bs_geo_loc_name
          } else if(len_bs_geo_loc_name == 0) {
            log_file$country <- "Missing_value"
          }
          # v1.6 added feature geo_loc_name (country)
          bs_geo_loc_name <- geo_loc_name[geo_loc_name$smp_id == sample_smp_id, "geo_loc_name"]
          ann_geo_loc_name <- head(ann[ann$Qualifier == "geo_loc_name",],n=1)$Value
          len_ann_geo_loc_name <- length(ann_geo_loc_name)
          len_bs_geo_loc_name <- length(bs_geo_loc_name)
          if(len_ann_geo_loc_name > 0 & len_bs_geo_loc_name > 0) {
            log_file$geo_loc_name <- bs_geo_loc_name
            log_file$geo_loc_name_ann <- ann_geo_loc_name
          } else if(len_ann_geo_loc_name > 0 & len_bs_geo_loc_name == 0) {
            log_file$geo_loc_name <- "Missing_value"
            log_file$geo_loc_name_ann <- ann_geo_loc_name
          } else if(len_ann_geo_loc_name == 0 & len_bs_geo_loc_name > 0) {
            log_file$geo_loc_name <- bs_geo_loc_name
            log_file$geo_loc_name_ann <- NA
          }
          # host name
          bs_hostname <- hostname[hostname$smp_id == sample_smp_id, ]$hostname
          len_bs_hostname <- length(bs_hostname)
          ann_hostname <- head(ann[ann$Qualifier == "host",'Value'],n=1)$Value
          len_ann_hostname <- length(ann_hostname)
          if(len_ann_hostname == 1 & len_bs_hostname == 1) {
            log_file$host <- bs_hostname
            log_file$host_ann <- ann_hostname
          } else if(len_ann_hostname == 0 & len_bs_hostname == 1) {
            log_file$host <- bs_hostname
            log_file$host_ann <- NA
          } else if(len_ann_hostname == 1 & len_bs_hostname == 0) {
            log_file$host <- "Missing_value"
            log_file$host_ann <- ann_hostname
          }
        } else if(length_sample_smp_id == 0) {
          log_file$smp_id <- "Missing_value"
          # add warning: smp_id is missing biosample_id might be wrong.
          errors_log <- paste("\nERROR MSS002: ", log_file$source, " missing smp_id, biosample_id might be wrong.\n", sep = "")
          cat(errors_log)
        }
      } else if(len_ann_biosample_id == 0) { # ann_biosample_id
        log_file$biosample_id_ann <- "Missing_value"
      }
      final_log_file <- rbind(final_log_file, log_file)
    }
    write.table(final_log_file, "/data/temp_autofix/out_mss_validation.tsv", row.names = F, col.names = T, quote = F, sep = "\t")
    write.table(final_feature_location, "/data/Rfixed/feature_location.tsv", row.names=F, col.names=T, quote=F, sep="\t")
  }
}

generate_report <- function() {
  line_out_mss_validation <- " wc -l /data/temp_autofix/out_mss_validation.tsv | cut -f1 -d\" \" "
  lines_out_mss_validation <- as.numeric(system(line_out_mss_validation, intern = T))
  if(lines_out_mss_validation > 1) {
    log <- fread("/data/temp_autofix/out_mss_validation.tsv", header = T, sep = "\t")
    log <- log[log$biosample_id_ann != "Missing_value", ]
    len_log <- dim(log)[1]
    # check if there are biosample_id_ann after removing Missing_value
    if(len_log > 0){
      final_log_file <- c()
      log$count <- 1
      check <- data.frame(matrix(ncol = 15, nrow = len_log))
      colnames(check) <- c('check_bp', 'check_org', 'check_smp', 'check_cnt', 'check_loc', 'check_coll', 'check_hst', 'check_stra', 'check_isol', 'check_cult', 'check_isosrc', 'check_ovlp', 'check_subsp', 'check_hokasubsp', 'check_geoloc')
      final_report <- data.frame(matrix(ncol = 6, nrow = 1))
      colnames(final_report) <- c('source', 'biosample_id_ann', 'biosample', 'ann_file', 'type', 'action')
      #final_report <- rbind(final_report, report)
      i <- 1
      for(i in 1:len_log) {
        if(!is.na(log$bioproject[i])) {
          if(!is.na(log$bioproject_ann[i])) {
            if(log$bioproject[i] == log$bioproject_ann[i]) {
              check$check_bp[i] <- 0
            } else {
              check$check_bp[i] <- 1
            }
          } else if(is.na(log$bioproject_ann[i])) {
            check$check_bp[i] <- -1
          }
        } else {
          check$check_bp[i] <- -2
        }
        if(!is.na(log$organism[i])) {
          if(!is.na(log$organism_ann[i])) {
            if(log$organism[i] == log$organism_ann[i]) {
              check$check_org[i] <- 0
            } else {
              check$check_org[i] <- 1
            }
          } else if(is.na(log$organism_ann[i])) {
            check$check_org[i] <- -1
          }
        } else {
          check$check_org[i] <- -2
        }
        # subsp
        if(!is.na(log$predicted_subsp_value[i])) {
          if(!is.na(log$predicted_subsp_value_ann[i])) {
            if(log$predicted_subsp_value[i] == log$predicted_subsp_value_ann[i]) {
              check$check_subsp[i] <- 0
            } else {
              check$check_subsp[i] <- 1
            }
          } else if(is.na(log$predicted_subsp_value_ann[i])) {
            check$check_subsp[i] <- -1
          }
        } else {
          check$check_subsp[i] <- -2
        }
        # other sub-species levels (hoka)
        if(!is.na(log$predicted_qualifier_value[i])) {
          if(!is.na(log$predicted_qualifier_value_ann[i])) {
            if(log$predicted_qualifier_value[i] == log$predicted_qualifier_value_ann[i]) {
              check$check_hokasubsp[i] <- 0
            } else {
              check$check_hokasubsp[i] <- 1
            }
          } else if(is.na(log$predicted_qualifier_value_ann[i])) {
            check$check_hokasubsp[i] <- -1
          }
        } else {
          check$check_hokasubsp[i] <- -2
        }
        # locus_tag
        if(!is.na(log$locus_tag[i])) {
          if(!is.na(log$locus_tag_ann[i])) {
            if(log$locus_tag[i] == log$locus_tag_ann[i]) {
              check$check_loc[i] <- 0
            } else {
              check$check_loc[i] <- 1
            }
          } else if(is.na(log$locus_tag_ann[i])) {
            check$check_loc[i] <- -1
          }
        } else {
          check$check_loc[i] <- -2
        }
        
        # check if feature country feature exists #
        if(!is.na(log$country_source_ann[i])) {
          check$check_cnt[i] <- -3
        }

        # geo_loc_name
        if(!is.na(log$geo_loc_name[i])) {
          if(!is.na(log$geo_loc_name_ann[i])) {
            if(log$geo_loc_name[i] == log$geo_loc_name_ann[i]) {
              check$check_geoloc[i] <- 0
            } else {
              check$check_geoloc[i] <- 1
            }
          } else if(is.na(log$geo_loc_name_ann[i])) {
            check$check_geoloc[i] <- -1
          }
        } else {
          check$check_geoloc[i] <- -2
        }
        
        if(!is.na(log$strain[i])) {
          if(!is.na(log$strain_ann[i])) {
            if(log$strain[i] == log$strain_ann[i]) {
              check$check_stra[i] <- 0
            } else {
              check$check_stra[i] <- 1
            }
          } else if(is.na(log$strain_ann[i])) {
            check$check_stra[i] <- -1
          }
        } else {
          check$check_stra[i] <- -2
        }
        if(!is.na(log$isolate[i])) {
          if(!is.na(log$isolate_ann[i])) {
            if(log$isolate[i] == log$isolate_ann[i]) {
              check$check_isol[i] <- 0
            } else {
              check$check_isol[i] <- 1
            }
          } else if(is.na(log$isolate_ann[i])) {
            check$check_isol[i] <- -1
          }
        } else {
          check$check_isol[i] <- -2
        }
        if(!is.na(log$cultivar[i])) {
          if(!is.na(log$cultivar_ann[i])) {
            if(log$cultivar[i] == log$cultivar_ann[i]) {
              check$check_cult[i] <- 0
            } else {
              check$check_cult[i] <- 1
            }
          } else if(is.na(log$cultivar_ann[i])) {
            check$check_cult[i] <- -1
          }
        } else {
          check$check_cult[i] <- -2
        }
        ###
        log$collection_date <- as.character(log$collection_date)
        log[log$collection_date == "not applicable",]$collection_date <- NA
        log[log$collection_date == "not collected",]$collection_date <- NA
        log[log$collection_date == "not provided",]$collection_date <- NA
        log[log$collection_date == "restricted access",]$collection_date <- NA
        log[log$collection_date == "missing",]$collection_date <- NA
        if(!is.na(log$collection_date[i])) {
          if(!is.na(log$collection_date_ann[i])) {
            if(as.character(log$collection_date[i]) == as.character(log$collection_date_ann[i])) {
              check$check_coll[i] <- 0
            } else {
              check$check_coll[i] <- 1
            }
          } else if(is.na(log$collection_date_ann[i])) {
            check$check_coll[i] <- -1
          }
        } else {
          check$check_coll[i] <- -2
        }
        if(!is.na(log$isolation_source[i])) {
          if(!is.na(log$isolation_source_ann[i])) {
            if(as.character(log$isolation_source[i]) == as.character(log$isolation_source_ann[i])) {
              check$check_isosrc[i] <- 0
            } else {
              check$check_isosrc[i] <- 1
            }
          } else if(is.na(log$isolation_source_ann[i])) {
            check$check_isosrc[i] <- -1
          }
        } else {
          check$check_isosrc[i] <- -2
        }
        # overlap
        if(!is.na(log$overlap[i])) {
          if(log$overlap[i] == "detected") {
            check$check_ovlp[i] <- 1
          }
        } else {
          check$check_ovlp[i] <- 0
        }
        # smp (attention if it is missing smp)
        if(!is.na(log$smp_id[i])) {
          if(log$smp_id[i] == "Missing_value") {
            check$check_smp[i] <- -2
          } else {
            check$check_smp[i] <- 0
          }
        }
        # host
        if(!is.na(log$host[i])) {
          if(!is.na(log$host_ann[i])) {
            if(log$host[i] == log$host_ann[i]) {
              check$check_hst[i] <- 0
            } else {
              check$check_hst[i] <- 1
            }
          } else if(is.na(log$host_ann[i])) {
            check$check_hst[i] <- -1
          }
        } else {
          check$check_hst[i] <- -2
        }
      }
      check$sum <- apply(check[,1:3], 1, sum) # check error in biosample_id
      test <- check
      pos_smp <- which(test$check_smp == -2)
      len_pos_smp <- length(pos_smp)
      test <- test[test$sum <= -3, ]
      len_test <- dim(test)[1]
      if(len_test >= 1) {
        if(len_log == len_test) {
          cat("\nERROR MSS003: There might have an error in the biosample_id, because ALL ANN files have too many errors comparing with Biosample DB. \n")
        } else {
          pos_test <- which(check$sum <= -3)
          ann_errors <- log[pos_test, ]$source
          message_test1 <- cat("\nERROR MSS003: There might have an error in the biosample_id, because there are too many errors, in the file(s) : \n")
          cat(message_test1)
          print(ann_errors)
        }
      }
      # bioproject
      fix_bp_pos <- which(check$check_bp == 1)
      add_ann_bp_pos <- which(check$check_bp == -1)
      add_meta_bp_pos <- which(check$check_bp == -2)
      len_fix_bp_pos <- length(fix_bp_pos)
      len_add_ann_bp_pos <- length(add_ann_bp_pos)
      len_add_meta_bp_pos <- length(add_meta_bp_pos)
      fix_bp_table <- c(); add_ann_bp_table <- c(); add_meta_bp_table <- c()
      if(len_fix_bp_pos > 0 | len_add_ann_bp_pos > 0 | len_add_meta_bp_pos > 0) {
        if(len_fix_bp_pos > 0) {
          fix_bp_table <- log[fix_bp_pos, c("source", "biosample_id_ann", "bioproject", "bioproject_ann")]
          fix_bp_table$type <- "project"
          fix_bp_table$action <- "replace"
        }
        if(len_add_ann_bp_pos > 0) {
          add_ann_bp_table <- log[add_ann_bp_pos, c("source", "biosample_id_ann", "bioproject", "bioproject_ann")]
          add_ann_bp_table$type <- "project"
          add_ann_bp_table$action <- "add"
        }
        if(len_add_meta_bp_pos > 0) {
          add_meta_bp_table <- log[add_ann_bp_pos, c("source", "biosample_id_ann", "bioproject", "bioproject_ann")]
          add_meta_bp_table$type <- "project"
          add_meta_bp_table$action <- "missing_biosample"
        }
        report <- rbind(fix_bp_table, add_ann_bp_table, add_meta_bp_table)
        colnames(report)[3:4] <- c("biosample", "ann_file")
        final_report <- rbind(final_report, report)
      }
      # organism
      fix_org_pos <- which(check$check_org == 1)
      add_ann_org_pos <- which(check$check_org == -1)
      add_meta_org_pos <- which(check$check_org == -2)
      len_fix_org_pos <- length(fix_org_pos)
      len_add_ann_org_pos <- length(add_ann_org_pos)
      len_add_meta_org_pos <- length(add_meta_org_pos)
      fix_org_table <- c(); add_ann_org_table <- c(); add_meta_org_table <- c()
      if(len_fix_org_pos > 0 | len_add_ann_org_pos > 0 | len_add_meta_org_pos > 0) {
        if(len_fix_org_pos > 0) {
          fix_org_table <- log[fix_org_pos, c("source", "biosample_id_ann", "organism", "organism_ann")]
          fix_org_table$type <- "organism"
          fix_org_table$action <- "replace"
        }
        if(len_add_ann_org_pos > 0) {
          add_ann_org_table <- log[add_ann_org_pos, c("source", "biosample_id_ann", "organism", "organism_ann")]
          add_ann_org_table$type <- "organism"
          add_ann_org_table$action <- "add"
        }
        if(len_add_meta_org_pos > 0) {
          add_meta_org_table <- log[add_meta_org_pos, c("source", "biosample_id_ann", "organism", "organism_ann")]
          add_meta_org_table$type <- "organism"
          add_meta_org_table$action <- "missing_biosample"
        }
        report <- rbind(fix_org_table, add_ann_org_table, add_meta_org_table)
        colnames(report)[3:4] <- c("biosample", "ann_file")
        final_report <- rbind(final_report, report)
      }
      # sub_species (mod v1.2)
      fix_subsp_pos <- which(check$check_subsp == 1)
      add_ann_subsp_pos <- which(check$check_subsp == -1)
      # add_meta_subsp_pos <- which(check$check_subsp == -2)
      len_fix_subsp_pos <- length(fix_subsp_pos)
      len_add_ann_subsp_pos <- length(add_ann_subsp_pos)
      # len_add_meta_subsp_pos <- length(add_meta_subsp_pos)
      fix_subsp_table <- c(); add_ann_subsp_table <- c(); add_meta_subsp_table <- c()
      # if(len_fix_subsp_pos > 0 | len_add_ann_subsp_pos > 0 | len_add_meta_subsp_pos > 0) {
      if( len_fix_subsp_pos > 0 | len_add_ann_subsp_pos > 0 ) {
        if(len_fix_subsp_pos > 0) {
          fix_subsp_table <- log[fix_subsp_pos, c("source", "biosample_id_ann", "predicted_subsp_value", "predicted_subsp_value_ann")]
          fix_subsp_table$type <- "sub_species"
          fix_subsp_table$action <- "replace"
        }
        if(len_add_ann_subsp_pos > 0) {
          add_ann_subsp_table <- log[add_ann_subsp_pos, c("source", "biosample_id_ann", "predicted_subsp_value", "predicted_subsp_value_ann")]
          add_ann_subsp_table$type <- "sub_species"
          add_ann_subsp_table$action <- "add"
        }
        # if(len_add_meta_subsp_pos > 0) {
        #   add_meta_subsp_table <- log[add_meta_subsp_pos, c("source", "biosample_id_ann", "predicted_subsp_value", "predicted_subsp_value_ann")]
        #   add_meta_subsp_table$type <- "sub_species"
        #   add_meta_subsp_table$action <- "missing_biosample"
        # }
        report <- rbind(fix_subsp_table, add_ann_subsp_table, add_meta_subsp_table)
        colnames(report)[3:4] <- c("biosample", "ann_file")
        final_report <- rbind(final_report, report)
      }
      # other sub-species level (hoka) # possible bug; type is missing in the report file!
      fix_hokasubsp_pos <- which(check$check_hokasubsp == 1)
      add_ann_hokasubsp_pos <- which(check$check_hokasubsp == -1)
      # add_meta_hokasubsp_pos <- which(check$check_hokasubsp == -2)
      len_fix_hokasubsp_pos <- length(fix_hokasubsp_pos)
      len_add_ann_hokasubsp_pos <- length(add_ann_hokasubsp_pos)
      # len_add_meta_hokasubsp_pos <- length(add_meta_hokasubsp_pos)
      fix_hokasubsp_table <- c(); add_ann_hokasubsp_table <- c(); add_meta_hokasubsp_table <- c()
      if(len_fix_hokasubsp_pos > 0 | len_add_ann_hokasubsp_pos > 0) {
        if(len_fix_hokasubsp_pos > 0) {
          fix_hokasubsp_table <- log[fix_hokasubsp_pos, c("source", "biosample_id_ann", "predicted_qualifier_value", "predicted_qualifier_value_ann")]
          fix_hokasubsp_table$type <- log$predicted_qualifier
          fix_hokasubsp_table$action <- "replace"
        }
        if(len_add_ann_hokasubsp_pos > 0) {
          add_ann_hokasubsp_table <- log[add_ann_hokasubsp_pos, c("source", "biosample_id_ann", "predicted_qualifier_value", "predicted_qualifier_value_ann")]
          add_ann_hokasubsp_table$type <- log$predicted_qualifier
          add_ann_hokasubsp_table$action <- "add"
        }
        # if(len_add_meta_hokasubsp_pos > 0 & len_add_ann_hokasubsp_pos > 0) {
        #   add_meta_hokasubsp_table <- log[add_meta_hokasubsp_pos, c("source", "biosample_id_ann", "predicted_qualifier_value", "predicted_qualifier_value_ann")]
        #   add_meta_hokasubsp_table$type <- log$predicted_qualifier
        #   add_meta_hokasubsp_table$action <- "missing_biosample"
        # }
        report <- rbind(fix_hokasubsp_table, add_ann_hokasubsp_table, add_meta_hokasubsp_table)
        colnames(report)[3:4] <- c("biosample", "ann_file")
        final_report <- rbind(final_report, report)
      }
      
      # locus_tag: check_loc
      fix_loc_pos <- which(check$check_loc == 1)
      add_ann_loc_pos <- which(check$check_loc == -1)
      add_meta_loc_pos <- which(check$check_loc == -2)
      len_fix_loc_pos <- length(fix_loc_pos)
      len_add_ann_loc_pos <- length(add_ann_loc_pos)
      len_add_meta_loc_pos <- length(add_meta_loc_pos)
      fix_loc_table <- c(); add_ann_loc_table <- c(); add_meta_loc_table <- c()
      if(len_fix_loc_pos > 0 | len_add_ann_loc_pos > 0 | len_add_meta_loc_pos > 0) {
        if(len_fix_loc_pos > 0) {
          fix_loc_table <- log[fix_loc_pos, c("source", "biosample_id_ann", "locus_tag", "locus_tag_ann")]
          fix_loc_table$type <- "locus_tag"
          fix_loc_table$action <- "replace"
        }
        if(len_add_ann_loc_pos > 0) {
          add_ann_loc_table <- log[add_ann_loc_pos, c("source", "biosample_id_ann", "locus_tag", "locus_tag_ann")]
          add_ann_loc_table$type <- "locus_tag"
          add_ann_loc_table$action <- "add"
        }
        if(len_add_meta_loc_pos > 0) {
          add_meta_loc_table <- log[add_meta_loc_pos, c("source", "biosample_id_ann", "locus_tag", "locus_tag_ann")]
          add_meta_loc_table$type <- "locus_tag"
          add_meta_loc_table$action <- "missing_biosample"
        }
        report <- rbind(fix_loc_table, add_ann_loc_table, add_meta_loc_table)
        colnames(report)[3:4] <- c("biosample", "ann_file")
        final_report <- rbind(final_report, report)
      }
      
      # country: check_cnt 
      remove_cnt_pos <- which(check$check_cnt == -3)
      len_remove_cnt_pos <- length(remove_cnt_pos)
      report <- c()
      if(len_remove_cnt_pos > 0) {
        report <- log[remove_cnt_pos, c("source", "biosample_id_ann", "country", "country_source_ann")]
        report$type <- "country"
        report$action <- "remove"
        colnames(report)[3:4] <- c("biosample", "ann_file")
        final_report <- rbind(final_report, report)
      }
      
      # geo_loc_name: check_geoloc
      fix_geoloc_pos <- which(check$check_geoloc == 1)
      add_ann_geoloc_pos <- which(check$check_geoloc == -1)
      add_meta_geoloc_pos <- which(check$check_geoloc == -2)
      len_fix_geoloc_pos <- length(fix_geoloc_pos)
      len_add_ann_geoloc_pos <- length(add_ann_geoloc_pos)
      len_add_meta_geoloc_pos <- length(add_meta_geoloc_pos)
      fix_geoloc_table <- c(); add_ann_geoloc_table <- c(); add_meta_geoloc_table <- c()
      if(len_fix_geoloc_pos > 0 | len_add_ann_geoloc_pos > 0 | len_add_meta_geoloc_pos > 0) {
        if(len_fix_geoloc_pos > 0) {
          fix_geoloc_table <- log[fix_geoloc_pos, c("source", "biosample_id_ann", "geo_loc_name", "geo_loc_name_ann")]
          fix_geoloc_table$type <- "geo_loc_name"
          fix_geoloc_table$action <- "replace"
        }
        if(len_add_ann_geoloc_pos > 0) {
          add_ann_geoloc_table <- log[add_ann_geoloc_pos, c("source", "biosample_id_ann", "geo_loc_name", "geo_loc_name_ann")]
          add_ann_geoloc_table$type <- "geo_loc_name"
          add_ann_geoloc_table$action <- "add"
        }
        if(len_add_meta_geoloc_pos > 0) {
          add_meta_geoloc_table <- log[add_meta_geoloc_pos, c("source", "biosample_id_ann", "geo_loc_name", "geo_loc_name_ann")]
          add_meta_geoloc_table$type <- "geo_loc_name"
          add_meta_geoloc_table$action <- "missing_biosample"
        }
        report <- rbind(fix_geoloc_table, add_ann_geoloc_table, add_meta_geoloc_table)
        colnames(report)[3:4] <- c("biosample", "ann_file")
        final_report <- rbind(final_report, report)
      }
      # collection_date: check_coll; remove entries if db has value: missing
      fix_coll_pos <- which(check$check_coll == 1)
      add_ann_coll_pos <- which(check$check_coll == -1)
      # add_meta_coll_pos <- which(check$check_coll == -2)
      len_fix_coll_pos <- length(fix_coll_pos)
      len_add_ann_coll_pos <- length(add_ann_coll_pos)
      # len_add_meta_coll_pos <- length(add_meta_coll_pos)
      fix_coll_table <- c(); add_ann_coll_table <- c(); add_meta_coll_table <- c()
      if(len_fix_coll_pos > 0 | len_add_ann_coll_pos > 0 ) {
        if(len_fix_coll_pos > 0) {
          fix_coll_table <- log[fix_coll_pos, c("source", "biosample_id_ann", "collection_date", "collection_date_ann")]
          fix_coll_table$collection_date <- as.character(fix_coll_table$collection_date)
          fix_coll_table$collection_date_ann <- as.character(fix_coll_table$collection_date_ann)
          fix_coll_table <- fix_coll_table[fix_coll_table$collection_date != "missing",] # attention database may have value missing
          fix_coll_table$type <- "collection_date"
          fix_coll_table$action <- "replace"
          len_fix_coll_table <- dim(fix_coll_table)[1]
          if(len_fix_coll_table == 0) {
            fix_coll_table <- c()
          }
        }
        if(len_add_ann_coll_pos > 0) {
          add_ann_coll_table <- log[add_ann_coll_pos, c("source", "biosample_id_ann", "collection_date", "collection_date_ann")]
          add_ann_coll_table$collection_date <- as.character(add_ann_coll_table$collection_date)
          add_ann_coll_table$collection_date_ann <- as.character(add_ann_coll_table$collection_date_ann)
          add_ann_coll_table$type <- "collection_date"
          add_ann_coll_table$action <- "add"
        }
        # if(len_add_meta_coll_pos > 0) {
        #   add_meta_coll_table <- log[add_meta_coll_pos, c("source", "biosample_id_ann", "collection_date", "collection_date_ann")]
        #   add_meta_coll_table$collection_date_ann <- as.character(add_meta_coll_table$collection_date_ann)
        #   add_meta_coll_table$type <- "collection_date"
        #   add_meta_coll_table$action <- "missing_biosample"
        # }
        report <- rbind(fix_coll_table, add_ann_coll_table, add_meta_coll_table)
        if(!is.null(report)) {
          colnames(report)[3:4] <- c("biosample", "ann_file")
          report$ann_file <- as.character(report$ann_file)
          final_report <- rbind(final_report, report) # (plyr::rbind.fill)## Bug in here!!!
        }
      }
      # isolation_source: check_isosrc
      fix_isosrc_pos <- which(check$check_isosrc == 1)
      add_ann_isosrc_pos <- which(check$check_isosrc == -1)
      # add_meta_isosrc_pos <- which(check$check_isosrc == -2)
      len_fix_isosrc_pos <- length(fix_isosrc_pos)
      len_add_ann_isosrc_pos <- length(add_ann_isosrc_pos)
      # len_add_meta_isosrc_pos <- length(add_meta_isosrc_pos)
      fix_isosrc_table <- c(); add_ann_isosrc_table <- c(); add_meta_isosrc_table <- c()
      if(len_fix_isosrc_pos > 0 | len_add_ann_isosrc_pos > 0 ) {
        if(len_fix_isosrc_pos > 0) {
          fix_isosrc_table <- log[fix_isosrc_pos, c("source", "biosample_id_ann", "isolation_source", "isolation_source_ann")]
          fix_isosrc_table$type <- "isolation_source"
          fix_isosrc_table$action <- "replace"
        }
        if(len_add_ann_isosrc_pos > 0) {
          add_ann_isosrc_table <- log[add_ann_isosrc_pos, c("source", "biosample_id_ann", "isolation_source", "isolation_source_ann")]
          add_ann_isosrc_table$type <- "isolation_source"
          add_ann_isosrc_table$action <- "add"
        }
        # if(len_add_meta_isosrc_pos > 0) {
        #   add_meta_isosrc_table <- log[add_meta_isosrc_pos, c("source", "biosample_id_ann", "isolation_source", "isolation_source_ann")]
        #   add_meta_isosrc_table$type <- "isolation_source"
        #   add_meta_isosrc_table$action <- "missing_biosample"
        # }
        report <- rbind(fix_isosrc_table, add_ann_isosrc_table, add_meta_isosrc_table)
        if(!is.null(report)) {
          colnames(report)[3:4] <- c("biosample", "ann_file")
          final_report <- rbind(final_report, report)
        }
      }
      # host: check_hst
      fix_hst_pos <- which(check$check_hst == 1)
      add_ann_hst_pos <- which(check$check_hst == -1)
      # add_meta_hst_pos <- which(check$check_hst == -2)
      len_fix_hst_pos <- length(fix_hst_pos)
      len_add_ann_hst_pos <- length(add_ann_hst_pos)
      # len_add_meta_hst_pos <- length(add_meta_hst_pos)
      fix_hst_table <- c(); add_ann_hst_table <- c(); add_meta_hst_table <- c()
      if(len_fix_hst_pos > 0 | len_add_ann_hst_pos > 0 ) {
        if(len_fix_hst_pos > 0) {
          fix_hst_table <- log[fix_hst_pos, c("source", "biosample_id_ann", "host", "host_ann")]
          fix_hst_table$type <- "host"
          fix_hst_table$action <- "replace"
        }
        if(len_add_ann_hst_pos > 0) {
          add_ann_hst_table <- log[add_ann_hst_pos, c("source", "biosample_id_ann", "host", "host_ann")]
          add_ann_hst_table$type <- "host"
          add_ann_hst_table$action <- "add"
        }
        # if(len_add_meta_hst_pos > 0) {
        #   add_meta_hst_table <- log[add_meta_hst_pos, c("source", "biosample_id_ann", "host", "host_ann")]
        #   add_meta_hst_table$type <- "host"
        #   add_meta_hst_table$action <- "missing_biosample"
        # }
        report <- rbind(fix_hst_table, add_ann_hst_table, add_meta_hst_table)
        colnames(report)[3:4] <- c("biosample", "ann_file")
        final_report <- rbind(final_report, report)
      }
      # overlap: check_ovlp
      fix_ovlp_pos <- which(check$check_ovlp == 1)
      len_fix_ovlp_pos <- length(fix_ovlp_pos)
      fix_ovlp_table <- c()
      if(len_fix_ovlp_pos > 0 ) {
        fix_ovlp_table <- log[fix_ovlp_pos, c("source", "biosample_id_ann", "overlap")]
        fix_ovlp_table$ann <- "detected_overlap"
        fix_ovlp_table$type <- "overlap"
        fix_ovlp_table$action <- "fix"
        report <- fix_ovlp_table
        colnames(report)[3:4] <- c("biosample", "ann_file")
        report$biosample <- "not_applicable"
        final_report <- rbind(final_report, report)
      }
      # strain, isolate, cultivar
      check$sum2 <- apply(check[, c("check_stra", "check_isol", "check_cult")], 1, sum)
      replace_subsp_pos <- which(check$sum2 == - 3) # there are only one sp sublevel for each entry, which is expected, and it is wrong
      len_replace_subsp_pos <- length(replace_subsp_pos) 
      check$qual_subs <- NA 
      
      
      
      test_all_subs <- check[check$check_isol == -2 & check$check_cult == -2 & check$check_stra == -2, ]$qual_subs
      len_test_all_subs <- length(test_all_subs)
      # test_strain <- check[check$check_isol == -2 & check$check_cult == -2 & check$check_stra != -2, ]$qual_subs # v1.4
      test_strain <- check[check$check_stra != -2 , ]$qual_subs
      len_test_strain <- length(test_strain)
      test_isolate <- check[check$check_stra == -2 & check$check_cult == -2 & check$check_isol != -2, ]$qual_subs
      len_test_isolate <- length(test_isolate)
      test_cultivar <- check[check$check_stra == -2 & check$check_isol == -2 & check$check_cult != -2, ]$qual_subs
      len_test_cultivar <- length(test_cultivar)
      if(len_test_all_subs > 0) {
        # there are no strain, isolate or cultivar
        check[check$check_isol == -2 & check$check_cult == -2 & check$check_stra == -2, ]$qual_subs <- "none"
      }
      if(len_test_strain > 0) {
        # v1.4
        # check[check$check_isol == -2 & check$check_cult == -2 & check$check_stra != -2, ]$qual_subs <- "strain"
        check[check$check_stra != -2, ]$qual_subs <- "strain"
        len_test_isolate <- 0
        len_test_cultivar <- 0
      } else if(len_test_isolate > 0) {
        check[check$check_stra == -2 & check$check_cult == -2 & check$check_isol != -2, ]$qual_subs <- "isolate"
      } else if(len_test_cultivar > 0) {
        check[check$check_stra == -2 & check$check_isol == -2 & check$check_cult != -2, ]$qual_subs <- "cultivar"
      }
      log$qual_subs <- check$qual_subs
      # v1.6
      fix_subsp_pos <- which(check$sum2 == -3)
      len_fix_subsp_pos <- length(fix_subsp_pos)
      add_ann_subsp_pos <- which(check$sum2 == -5)
      len_add_ann_subsp_pos <- length(add_ann_subsp_pos)
      # add_meta_subsp_pos <- which(check$sum2 == -6)
      # len_add_meta_subsp_pos <- length(add_meta_subsp_pos)
      all_fix_subsp_table <- c(); fix_subsp_table <- c(); all_add_ann_subsp_table <- c(); add_ann_subsp_table <- c(); add_meta_subsp_table <- c()
      if (len_fix_subsp_pos >  0 | len_add_ann_subsp_pos > 0 ) {
        if(len_fix_subsp_pos > 0) {
          for(m in 1:len_fix_subsp_pos){
            if(log$qual_subs[m] == "strain") { # bug -> value is NA
              fix_subsp_table <- log[fix_subsp_pos[m], c("source", "biosample_id_ann", "strain", "strain_ann")]
              colnames(fix_subsp_table)[3:4] <- c("subsp", "subsp_ann")
              fix_subsp_table$type <- "strain"
              fix_subsp_table$action <- "replace"
            } else if(log$qual_subs == "isolate") {
              fix_subsp_table <- log[fix_subsp_pos[m], c("source", "biosample_id_ann", "isolate", "isolate_ann")]
              colnames(fix_subsp_table)[3:4] <- c("subsp", "subsp_ann")
              fix_subsp_table$type <- "isolate"
              fix_subsp_table$action <- "replace"
            } else if(log$qual_subs == "cultivar") {
              fix_subsp_table <- log[fix_subsp_pos[m], c("source", "biosample_id_ann", "cultivar", "cultivar_ann")]
              colnames(fix_subsp_table)[3:4] <- c("subsp", "subsp_ann")
              fix_subsp_table$type <- "cultivar"
              fix_subsp_table$action <- "replace"
            }
            all_fix_subsp_table <- rbind(all_fix_subsp_table, fix_subsp_table)
          }
        } else if(len_add_ann_subsp_pos > 0) {
          for(n in 1:len_add_ann_subsp_pos){
            if(log$qual_subs[n] == "strain") {
              add_ann_subsp_table <- log[add_ann_subsp_pos[n], c("source", "biosample_id_ann", "strain", "strain_ann")]
              colnames(add_ann_subsp_table)[3:4] <- c("subsp", "subsp_ann")
              add_ann_subsp_table$type <- "strain"
              add_ann_subsp_table$action <- "add"
            } else if(log$qual_subs == "isolate") {
              add_ann_subsp_table <- log[add_ann_subsp_pos[n], c("source", "biosample_id_ann", "isolate", "isolate_ann")]
              colnames(add_ann_subsp_table)[3:4] <- c("subsp", "subsp_ann")
              add_ann_subsp_table$type <- "isolate"
              add_ann_subsp_table$action <- "add"
            } else if(log$qual_subs == "cultivar") {
              add_ann_subsp_table <- log[add_ann_subsp_pos[n], c("source", "biosample_id_ann", "cultivar", "cultivar_ann")]
              colnames(add_ann_subsp_table)[3:4] <- c("subsp", "subsp_ann")
              add_ann_subsp_table$type <- "cultivar"
              add_ann_subsp_table$action <- "add"
            }
            all_add_ann_subsp_table <- rbind(all_add_ann_subsp_table, add_ann_subsp_table)
          }
        }
        report <- rbind(all_fix_subsp_table, all_add_ann_subsp_table)
        colnames(report)[3:4] <- c("biosample", "ann_file")
        final_report <- rbind(final_report, report)
      }
      ###
      final_report <- final_report[!is.na(final_report$source), ]
      final_report <- final_report[final_report$action != "missing_biosample", ]
      final_report <- final_report[final_report$biosample != "not applicable", ]
      len_final_report <- dim(final_report)[1]
      if(len_final_report > 0) {
        final_report <- final_report[order(final_report$type, final_report$source),]
        write.table(final_report, "/data/Rfixed/confirmation_report.tsv", row.names = F, col.names = T, quote = F, sep = "\t")
      }
    } else { # len_log
      cat("\nERROR MSS001: Missing biosample_id on ann file.", "\n")
    }
  } #lines_out_mss_validation
}

ddbj_mss_validation()
generate_report()
