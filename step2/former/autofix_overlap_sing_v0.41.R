# dependencies:
require(data.table)
# require(stringr)

autofix_overlap <- function() {
  feature_location <- read.table("/data/temp_autofix/feature_location.tsv", header = F, sep = "\t")
  colnames(feature_location) <- c( "source", "Entry", "cds_location", "assembly_gap_location", "temp_cds", "cds_start", "cds_end", "gap_start",	"gap_end", "new_cds_end",	"new_cds_start", "len_cds1", "len_cds2")
  feature_location$count <- 1
  # aggregate overlapping assembly_gap in the same CDS
  agg <- aggregate(feature_location$count,by = list(Entry = feature_location$Entry, cds_location = feature_location$cds_location), FUN = sum)
  colnames(agg)[3] <- "count"
  agg <- agg[order(agg$count,decreasing=T),]
  n_gap_overlaps <- agg[agg$count > 1, ]
  len_n_gap_overlaps <- dim(n_gap_overlaps)[1]
  if(len_n_gap_overlaps > 0){
    message_agg <- paste("\n",feature_location$source[1],": Entry [", n_gap_overlaps$Entry, "] position [", n_gap_overlaps$cds_location, "] has [", n_gap_overlaps$count, "] assembly_gaps overlapping CDS. It will not be fixed. \n", sep="")
    print(agg)
    cat(message_agg)
  }
  # aggregate overlapping CDS in the same assembly_gap: new function: skip cases where one assembly_gap overlaps more than one CDS.
  agg2 <- aggregate(feature_location$count,by = list(Entry = feature_location$Entry, assembly_gap_location = feature_location$assembly_gap_location), FUN = sum)
  colnames(agg2)[3] <- "count"
  agg2 <- agg2[order(agg2$count,decreasing=T),]
  n_gap_overlaps2 <- agg2[agg2$count > 1, ]
  len_n_gap_overlaps2 <- dim(n_gap_overlaps2)[1]
  if(len_n_gap_overlaps2 > 0){
    message_agg2 <- paste("\n",feature_location$source[1],": Entry [", n_gap_overlaps2$Entry, "] position [", n_gap_overlaps2$assembly_gap_location, "] has [", n_gap_overlaps2$count, "] CDS overlapping assembly_gaps. It will not be fixed. \n", sep="")
    print(agg2)
    cat(message_agg2)
  }
  # end of function aggregate overlapping CDS in the same assembly_gap
  unique_gap_overlap <- agg[agg$count == 1, c("Entry", "cds_location")]
  len_unique_gap_overlap <- dim(unique_gap_overlap)[1]
  unique_gap_overlap2 <- agg2[agg2$count == 1, c("Entry", "assembly_gap_location")] # new
  if(len_unique_gap_overlap > 0){ # check if there are no entry with count == 1
    feature_location <- merge(feature_location, unique_gap_overlap, by = c("Entry", "cds_location"))
    feature_location <- merge(feature_location, unique_gap_overlap2, by = c("Entry", "assembly_gap_location")) # new
    feature_location[feature_location$len_cds1 <= 50,'cds_start'] <- NA
    feature_location[feature_location$len_cds1 <= 50,'new_cds_end'] <- NA
    feature_location[feature_location$len_cds2 <= 50,'new_cds_start'] <- NA
    feature_location[feature_location$len_cds2 <= 50,'cds_end'] <- NA
    # check if still remain lines on feature_location
    len_test_fea_loc <- dim(feature_location)[1]
    if(len_test_fea_loc > 0){
      feature_location$new_location <- ""
      for(k in 1:len_test_fea_loc){
        is_complementar <- grep("complement",feature_location$cds_location[k])
        len_is_complementar <- length(is_complementar)
        if(is.na(feature_location$cds_start[k])){
          feature_location$new_location[k] <- paste("<",feature_location$new_cds_start[k],"..",feature_location$cds_end[k], sep="")
          if(len_is_complementar == 1){
            feature_location$new_location[k] <- paste("complement(",feature_location$new_location[k],")", sep="")
          }
        }else if(is.na(feature_location$cds_end[k])){
          feature_location$new_location[k] <- paste(feature_location$cds_start[k],"..>",feature_location$new_cds_end[k], sep="")
          if(len_is_complementar == 1){
            feature_location$new_location[k] <- paste("complement(",feature_location$new_location[k],")", sep="")
          }
        }
      }
      # open ann file
      # file2fix <- paste("Rfixed", feature_location$source[1], sep="/") # bug do not open a file on Rfixed directory, but run autofix_overlap first!
      file2fix <- as.character(feature_location$source[1]) # v0.3
      ann <- fread(file2fix , header=F, sep="\t", fill=T)[,1:5]
      colnames(ann) <- c("Entry", "Feature", "Location", "Qualifier", "Value")
      # loop on feature_location
      i <- 1
      for(i in 1:len_test_fea_loc){
        len_ann <- dim(ann)[1]
        entry <- feature_location$Entry[i]
        
        # pos_entry <- which(ann$Feature == "source") v0.6; match ddbj_mss_validation_v2.3
        # all_entries <- ann[ann$Feature == "source",'Entry']
        pos_entry <- which(ann$Entry != "" & ann$Entry != "COMMON") # remove line 1: COMMON
        all_entries <- ann[(ann$Entry != "" & ann$Entry != "COMMON"), "Entry"]
        
        len_all_entries <- dim(all_entries)[1]
        # print(len_all_entries)
        all_entries$pos_entry <- pos_entry
        end_pos <- all_entries$pos_entry[2:len_all_entries] - 1
        end_pos <- c(end_pos,len_ann)
        all_entries$end_pos <- end_pos
        #
        contig_position <- all_entries[all_entries$Entry == entry,]
        # split ann file in 3; # create a temporary ann file 'entry2fix' for processing change
        before <- ann[1:(contig_position$pos_entry -1),]
        entry2fix <- ann[contig_position$pos_entry:contig_position$end_pos,]
        len_entry2fix <- dim(entry2fix)[1]
        if(contig_position$end_pos < len_ann){
          after <- ann[(contig_position$end_pos +1):len_ann,]
          check_after <- 1
        } else {
          check_after <- 0
        }
        #
        is_complementar <- grep("complement",feature_location$cds_location[i])
        len_is_complementar <- length(is_complementar)
        if(!is.na(feature_location$cds_start[i]) & !is.na(feature_location$new_cds_start[i]) & len_is_complementar == 0){
          ## check bug
          pos_on_entry2fix_file <- grep(feature_location$temp_cds[i],entry2fix$Location)
          gap_pos_on_entry2fix_file <- grep(feature_location$assembly_gap_loc[i],entry2fix$Location)
          # bug is here !!!
          before_feature2fix <- entry2fix[1:(pos_on_entry2fix_file -1),]
          # considering 3 lines for assembly_gap
          gap_assembly_lines <- entry2fix[gap_pos_on_entry2fix_file:(gap_pos_on_entry2fix_file+2),]
          if((gap_pos_on_entry2fix_file +3) < len_entry2fix){
            after_feature2fix <- entry2fix[(gap_pos_on_entry2fix_file +3):len_entry2fix,]
          }
          #
          feature2fix1 <- entry2fix[pos_on_entry2fix_file:(gap_pos_on_entry2fix_file -1),]
          feature2fix2 <- feature2fix1
          feature2fix1$Location[1] <- paste(feature_location$cds_start[i],"..>",feature_location$new_cds_end[i], sep="")
          feature2fix2$Location[1] <- paste("<",feature_location$new_cds_start[i],"..",feature_location$cds_end[i], sep="")
          # check codon_start; first check rest of division example: 9%%3
          restofdivision <- (feature_location$cds_end[i] - feature_location$new_cds_start[i] + 1)%%3
          if(restofdivision == 0){
             feature2fix2[feature2fix2$Qualifier == "codon_start",'Value'] <- 1
          }else if(restofdivision == 1){
             feature2fix2[feature2fix2$Qualifier == "codon_start",'Value'] <- 2
          }else if(restofdivision == 2){
             feature2fix2[feature2fix2$Qualifier == "codon_start",'Value'] <- 3
          }
          #
          if((gap_pos_on_entry2fix_file +3) < len_entry2fix){
            fixed_entry <- rbind(before_feature2fix,feature2fix1,gap_assembly_lines,feature2fix2,after_feature2fix)
          }else{
            fixed_entry <- rbind(before_feature2fix,feature2fix1,gap_assembly_lines,feature2fix2)
          }
          if(check_after > 0){
            ann <- rbind(before,fixed_entry,after)
          } else {
            ann <- rbind(before,fixed_entry)
          }
        }else if(!is.na(feature_location$cds_start[i]) & !is.na(feature_location$new_cds_start[i]) & len_is_complementar == 1){
          pos_on_entry2fix_file <- grep(feature_location$temp_cds[i],entry2fix$Location)
          gap_pos_on_entry2fix_file <- grep(feature_location$assembly_gap_loc[i],entry2fix$Location)
          #
          before_feature2fix <- entry2fix[1:(pos_on_entry2fix_file -1),]
          # considering 3 lines for assembly_gap
          gap_assembly_lines <- entry2fix[gap_pos_on_entry2fix_file:(gap_pos_on_entry2fix_file+2),]
          if((gap_pos_on_entry2fix_file +3) < len_entry2fix){
            after_feature2fix <- entry2fix[(gap_pos_on_entry2fix_file +3):len_entry2fix,]
          }
          #
          feature2fix1 <- entry2fix[pos_on_entry2fix_file:(gap_pos_on_entry2fix_file -1),]
          feature2fix2 <- feature2fix1
          feature2fix1$Location[1] <- paste("complement(", feature_location$cds_start[i],"..>",feature_location$new_cds_end[i],")", sep="")
          feature2fix2$Location[1] <- paste("complement(<",feature_location$new_cds_start[i],"..",feature_location$cds_end[i],")", sep="")
          # check codon_start; first check rest of division example: 9%%3 == 0
          restofdivision <- (feature_location$new_cds_end[i] - feature_location$cds_start[i] + 1)%%3
          if(restofdivision == 0){
             feature2fix1[feature2fix1$Qualifier == "codon_start",'Value'] <- 1
          }else if(restofdivision == 1){
             feature2fix1[feature2fix1$Qualifier == "codon_start",'Value'] <- 2
          }else if(restofdivision == 2){
             feature2fix1[feature2fix1$Qualifier == "codon_start",'Value'] <- 3
          }
          # merge files
          if((gap_pos_on_entry2fix_file +3) < len_entry2fix){
            fixed_entry <- rbind(before_feature2fix,feature2fix1,gap_assembly_lines,feature2fix2,after_feature2fix)
          }else{
            fixed_entry <- rbind(before_feature2fix,feature2fix1,gap_assembly_lines,feature2fix2)
          }
          if(check_after > 0){
            ann <- rbind(before,fixed_entry,after)
          } else {
            ann <- rbind(before,fixed_entry)
          }
        }else if(is.na(feature_location$cds_start[i])){ # i=17 (feature_location line 17, NJB14192DDBJ.ann); removed 2CDS overlap 1assemble_gap
          pos_on_entry2fix_file <- grep(feature_location$temp_cds[i],entry2fix$Location)
          gap_pos_on_entry2fix_file <- grep(feature_location$assembly_gap_loc[i],entry2fix$Location)
          #
          before_feature2fix <- entry2fix[1:(pos_on_entry2fix_file -1),]
          # considering 3 lines for assembly_gap
          gap_assembly_lines <- entry2fix[gap_pos_on_entry2fix_file:(gap_pos_on_entry2fix_file+2),]
          if((gap_pos_on_entry2fix_file +3) < len_entry2fix){
            after_feature2fix <- entry2fix[(gap_pos_on_entry2fix_file +3):len_entry2fix,]
          }
          feature2fix1 <- entry2fix[pos_on_entry2fix_file:(gap_pos_on_entry2fix_file -1),]
          feature2fix1[1,'Location'] <- feature_location$new_location[i]
          # check codon_start
          # not complementar
          if(len_is_complementar == 0){
            restofdivision <- (feature_location$cds_end[i] - feature_location$new_cds_start[i] + 1)%%3
            if(restofdivision == 0){
               feature2fix1[feature2fix1$Qualifier == "codon_start",'Value'] <- 1 # make sure that there are only one CDS for each assembly_gap.
            }else if(restofdivision == 1){
               feature2fix1[feature2fix1$Qualifier == "codon_start",'Value'] <- 2
            }else if(restofdivision == 2){
               feature2fix1[feature2fix1$Qualifier == "codon_start",'Value'] <- 3
            }
          }
          # merge files
          if((gap_pos_on_entry2fix_file +3) < len_entry2fix){
            fixed_entry <- rbind(before_feature2fix,gap_assembly_lines,feature2fix1,after_feature2fix)
          }else{
            fixed_entry <- rbind(before_feature2fix,gap_assembly_lines,feature2fix1)
          }
          if(check_after > 0){
            ann <- rbind(before,fixed_entry,after)
          } else {
            ann <- rbind(before,fixed_entry)
          }
        }else if(is.na(feature_location$cds_end[i])){
          pos_on_entry2fix_file <- grep(feature_location$temp_cds[i],entry2fix$Location)[1]

          gap_pos_on_entry2fix_file <- grep(feature_location$assembly_gap_loc[i],entry2fix$Location)[1]
          #
          before_feature2fix <- entry2fix[1:(pos_on_entry2fix_file -1),]
          # considering 3 lines for assembly_gap
          gap_assembly_lines <- entry2fix[gap_pos_on_entry2fix_file:(gap_pos_on_entry2fix_file+2),]
          if((gap_pos_on_entry2fix_file +3) < len_entry2fix){
            after_feature2fix <- entry2fix[(gap_pos_on_entry2fix_file +3):len_entry2fix,]
          }
          feature2fix1 <- entry2fix[pos_on_entry2fix_file:(gap_pos_on_entry2fix_file -1),]
          feature2fix1[1,'Location'] <- feature_location$new_location[i]
          # check codon_start
          # is complementar
          if(len_is_complementar == 1){
            restofdivision <- (feature_location$new_cds_end[i] - feature_location$cds_start[i] + 1)%%3
            if(restofdivision == 0){
               feature2fix1[feature2fix1$Qualifier == "codon_start",'Value'] <- 1
            }else if(restofdivision == 1){
               feature2fix1[feature2fix1$Qualifier == "codon_start",'Value'] <- 2
            }else if(restofdivision == 2){
               feature2fix1[feature2fix1$Qualifier == "codon_start",'Value'] <- 3
            }
          }
          # merge files
          if((gap_pos_on_entry2fix_file +3) < len_entry2fix){
            fixed_entry <- rbind(before_feature2fix,feature2fix1,gap_assembly_lines,after_feature2fix)
          }else{
            fixed_entry <- rbind(before_feature2fix,feature2fix1,gap_assembly_lines)
          }
          if(check_after > 0){
            ann <- rbind(before,fixed_entry,after)
          } else {
            ann <- rbind(before,fixed_entry)
          }
         }
      } # end of loop on feature_location
    } # len_test_fea_loc
    write.table(ann, file2fix, row.names = F, col.names = F, quote = F, sep = "\t")
  } else { # len_unique_gap_overlap
    # assembly_gap overlap CDS was not fixed.
    cat("\nWARNING AFX001: None assembly_gap overlap CDS was fixed.", "\n")
  }
} # end of function

autofix_overlap()
