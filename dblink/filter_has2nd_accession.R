###
# filter bioproject, biosample and DRR from *_has2nd_accession
###
suppressMessages(require(data.table))
filename <- c("temp/at101_has2nd_accession_accept_date.txt","temp/at102_has2nd_accession_accept_date.txt") # nolint
source <- c("at101_has2nd", "at102_has2nd")
server <- c("e-actual", "g-actual")
pattern <- c("NA", "PRJ[A-Z][A-Z]", "SAM[A-Z]", "[A-Z]RR")
patname <- c("bp_noBioproject", "bp", "biosample", "drr")
i <- 1
for (i in 1:2){
    if (file.exists(filename[i])) {
        dt <- fread(filename[i], header = FALSE, sep = ",")
        colnames(dt) <- c("accession", "dblink", "taxon", "status", "date")
        dt$dblink <- as.character(dt$dblink)
        dt[is.na(dt$dblink) | dt$dblink == "",]$dblink <- "NA"
        dt[is.na(dt$date) | dt$date == "",]$date <- as.IDate("1900-01-01", format = "%Y-%m-%d") # nolint
        j <- 1
        # for(j in 1:length(pattern)){
        for (j in 1:1){
            datatype <- dt[grep(pattern[j], dt$dblink),]
            if (dim(datatype)[1] > 0) {
                datatype$server <- server[i]
                datatype$count <- 1
                if (j <= 2) {
                    datatype <- datatype[, c("server", "accession", "dblink", "taxon", "status", "date", "count")] # nolint
                } else {
                    datatype <- datatype[, c("accession", "dblink")]
                }
                output <- paste(patname[j], source[i], "actual.txt", sep = "_")
                fwrite(datatype, output, row.names=F, col.names=F, quote=F, sep = ",") # nolint
            }
        }
    } else {
        message <- paste("file", filename[i], "do not exist", sep=" ")
        print(message)
    }
}
