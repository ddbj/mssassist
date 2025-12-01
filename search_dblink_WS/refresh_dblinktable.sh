#!/bin/bash
LOGFILE="/home/systool/Log/update_dblinkddbj.log"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOGFILE" 2>&1
}

log "Update tables started"

# Import dblink_ddbj_standby
cd /home/systool/DBLINK_DDBJ
rsync -vrlt --delete sc-tkosuge:/home/w3const/dblink-ddbj/dblink_ddbj_standby ./

db="dblink_ddbj_devel"
current_date=$(date +%Y-%m-%d)
# db="dblink_ddbj_standby"
# gea_dblink
extracted_date=$(ls -l --time-style=full-iso /home/systool/DBLINK_DDBJ/dblink_ddbj_standby/gea/gea_dblink.csv |cut -f6 -d" " )
if [[ "$extracted_date" = "$current_date" ]]; then
  log "Uploading gea_dblink"
  psql -d ${db} -c "DROP TABLE gea_dblink;"
  psql -d ${db} -c "CREATE TABLE gea_dblink(
    id SERIAL,
    gea VARCHAR(20) NOT NULL,
    status VARCHAR(14),
    bioproject VARCHAR(20),
    PRIMARY KEY (id, gea)
  );"
  psql -d ${db} -c "COPY gea_dblink(gea,status,bioproject)
  FROM '/home/systool/DBLINK_DDBJ/dblink_ddbj_standby/gea/gea_dblink.csv'
  DELIMITER ','; "
else
  log "File gea_dblink.csv is old, last update: ${extracted_date}."
fi
# trad_bioproject
extracted_date=$(ls -l --time-style=full-iso /home/systool/DBLINK_DDBJ/dblink_ddbj_standby/tsunami/bp_actual_taxon.csv | cut -f6 -d" " )
if [[ "$extracted_date" = "$current_date" ]]; then
  log "Uploading trad_bioproject"
  psql -d ${db} -c "DROP TABLE trad_bioproject; "
  psql -d ${db} -c "CREATE TABLE trad_bioproject(
    id_trad_bp SERIAL,
    db_name VARCHAR(8) NOT NULL,
    accession VARCHAR(20) NOT NULL,
    bioproject VARCHAR(20) NOT NULL,
    taxon INTEGER,
    status VARCHAR(14),
    accept_date DATE,
    count INTEGER,
    PRIMARY KEY (id_trad_bp, accession, bioproject)
  );"
  psql -d ${db} -c "COPY trad_bioproject(db_name,accession,bioproject,taxon,status,accept_date,count)
  FROM '/home/systool/DBLINK_DDBJ/dblink_ddbj_standby/tsunami/bp_actual_taxon.csv'
  DELIMITER ',';"
  psql -d ${db} -c "UPDATE trad_bioproject SET status = 'private' WHERE status = '1001';"
  psql -d ${db} -c "UPDATE trad_bioproject SET status = 'public' WHERE status = '1002';"
  psql -d ${db} -c "UPDATE trad_bioproject SET status = 'suppressed' WHERE status = '1004';"
  psql -d ${db} -c "UPDATE trad_bioproject SET status = 'secondary' WHERE status = '1005';"
  psql -d ${db} -c "UPDATE trad_bioproject SET status = 'killed' WHERE status = '1006';"
  psql -d ${db} -c "UPDATE trad_bioproject SET status = 'unregistered' WHERE status = '1007';"
else
  log "File bp_actual_taxon.csv is old, last update: ${extracted_date}."
fi
# trad_biosample
extracted_date=$(ls -l --time-style=full-iso /home/systool/DBLINK_DDBJ/dblink_ddbj_standby/tsunami/biosample_actual.csv | cut -f6 -d" " )
if [[ "$extracted_date" = "$current_date" ]]; then
  log "Uploading trad_biosample"
  psql -d ${db} -c "DROP TABLE trad_biosample; "
  psql -d ${db} -c "CREATE TABLE trad_biosample(
    id SERIAL,
    accession VARCHAR(20) NOT NULL,
    biosample VARCHAR(20) NOT NULL,
    PRIMARY KEY (id, accession)
    ); "
  psql -d ${db} -c "COPY trad_biosample(accession,biosample)
  FROM '/home/systool/DBLINK_DDBJ/dblink_ddbj_standby/tsunami/biosample_actual.csv'
  DELIMITER ',';"
else
  log "File biosample_actual.csv is old, last update: ${extracted_date}."
fi

# trad_sra
extracted_date=$(ls -l --time-style=full-iso /home/systool/DBLINK_DDBJ/dblink_ddbj_standby/tsunami/drr_actual.csv | cut -f6 -d" " )
if [[ "$extracted_date" = "$current_date" ]]; then
  log "Uploading trad_sra"
  psql -d ${db} -c "DROP TABLE trad_sra; "
  psql -d ${db} -c "CREATE TABLE trad_sra(
    id SERIAL,
    accession VARCHAR(20) NOT NULL,
    drr VARCHAR(20) NOT NULL,
    PRIMARY KEY (id,accession)
    ); "
  psql -d ${db} -c "COPY trad_sra(accession,drr)
  FROM '/home/systool/DBLINK_DDBJ/dblink_ddbj_standby/tsunami/drr_actual.csv'
  DELIMITER ',';"
else
  log "File drr_actual.csv is old, last update: ${extracted_date}."
fi

# trace_biosample
extracted_date=$(ls -l --time-style=full-iso /home/systool/DBLINK_DDBJ/dblink_ddbj_standby/trace/dblink_trace_bs_table.csv | cut -f6 -d" " )
if [[ "$extracted_date" = "$current_date" ]]; then
  log "Uploading trace_biosample"
  psql -d ${db} -c "DROP TABLE trace_biosample; "
  psql -d ${db} -c "CREATE TABLE trace_biosample(
    id SERIAL,
    biosample VARCHAR(20),
    submitter VARCHAR(30),
    submission VARCHAR(15),
    status VARCHAR(14),
    taxon INT,
    locus_tag VARCHAR(15),
    bioproject VARCHAR(20),
    PRIMARY KEY (id, biosample)
    ); "
  psql -d ${db} -c "COPY trace_biosample(biosample,submitter,submission,status,taxon,locus_tag,bioproject)
  FROM '/home/systool/DBLINK_DDBJ/dblink_ddbj_standby/trace/dblink_trace_bs_table.csv' (FORMAT csv, null 'NULL', DELIMITER ',') ;"
  psql -d ${db} -c "UPDATE trace_biosample SET status = 'submitted' WHERE status = '5100';"
  psql -d ${db} -c "UPDATE trace_biosample SET status = 'curating' WHERE status = '5200';"
  psql -d ${db} -c "UPDATE trace_biosample SET status = 'private' WHERE status = '5400';"
  psql -d ${db} -c "UPDATE trace_biosample SET status = 'public' WHERE status = '5500';"
  psql -d ${db} -c "UPDATE trace_biosample SET status = 'killed' WHERE status = '5600';"
  psql -d ${db} -c "UPDATE trace_biosample SET status = 'canceled' WHERE status = '5700';"
  psql -d ${db} -c "UPDATE trace_biosample SET status = 'suppressed' WHERE status = '5800';"
else
  log "File dblink_trace_bs_table.csv is old, last update: ${extracted_date}."
fi

# trace_bioproject
extracted_date=$(ls -l --time-style=full-iso /home/systool/DBLINK_DDBJ/dblink_ddbj_standby/trace/dblink_trace_bp_table.csv | cut -f6 -d" " )
if [[ "$extracted_date" = "$current_date" ]]; then
  log "Uploading trace_bioproject"
  psql -d ${db} -c "DROP TABLE trace_bioproject; "
  psql -d ${db} -c "CREATE TABLE trace_bioproject(
    id SERIAL,
    submitter VARCHAR(30),
    submission VARCHAR(15),
    status VARCHAR(14),
    project_type VARCHAR(12),
    locus_tag VARCHAR(15),
    bioproject VARCHAR(20),
    PRIMARY KEY (id, bioproject)
    ); "
  psql -d ${db} -c "COPY trace_bioproject(submitter,submission,status,project_type,locus_tag,bioproject)
  FROM '/home/systool/DBLINK_DDBJ/dblink_ddbj_standby/trace/dblink_trace_bp_table.csv' (FORMAT csv, null 'NULL', DELIMITER ',') ;"
  psql -d ${db} -c "UPDATE trace_bioproject SET status = 'submitted' WHERE status = '5100';"
  psql -d ${db} -c "UPDATE trace_bioproject SET status = 'curating' WHERE status = '5200';"
  psql -d ${db} -c "UPDATE trace_bioproject SET status = 'private' WHERE status = '5400';"
  psql -d ${db} -c "UPDATE trace_bioproject SET status = 'public' WHERE status = '5500';"
  psql -d ${db} -c "UPDATE trace_bioproject SET status = 'killed' WHERE status = '5600';"
  psql -d ${db} -c "UPDATE trace_bioproject SET status = 'canceled' WHERE status = '5700';"
  psql -d ${db} -c "UPDATE trace_bioproject SET status = 'suppressed' WHERE status = '5800';"
else
  log "File dblink_trace_bp_table.csv is old, last update: ${extracted_date}."
fi

# trace_drr
extracted_date=$(ls -l --time-style=full-iso /home/systool/DBLINK_DDBJ/dblink_ddbj_standby/trace/dblink_trace_drr_table_status.csv | cut -f6 -d" " )
if [[ "$extracted_date" = "$current_date" ]]; then
  log "Uploading trace_drr"
  psql -d ${db} -c "DROP TABLE trace_drr; "
  psql -d ${db} -c "CREATE TABLE trace_drr(
    id SERIAL,
    drr VARCHAR(15) NOT NULL,
    bioproject VARCHAR(20),
    biosample VARCHAR(20),
    submitter VARCHAR(30),
    status VARCHAR(14),
    PRIMARY KEY (id, drr)
  ); "
  psql -d ${db} -c "COPY trace_drr(drr,bioproject,biosample,submitter,status)
  FROM '/home/systool/DBLINK_DDBJ/dblink_ddbj_standby/trace/dblink_trace_drr_table_status.csv'
  DELIMITER ',';"
  psql -d ${db} -c "UPDATE trace_drr SET status = 'error' WHERE status = '390';"
  psql -d ${db} -c "UPDATE trace_drr SET status = 'submitted' WHERE status = '400';"
  psql -d ${db} -c "UPDATE trace_drr SET status = 'submitted' WHERE status = '500';"
  psql -d ${db} -c "UPDATE trace_drr SET status = 'private' WHERE status = '700';"
  psql -d ${db} -c "UPDATE trace_drr SET status = 'private' WHERE status = '750';"
  psql -d ${db} -c "UPDATE trace_drr SET status = 'public' WHERE status = '800';"
else
  log "File dblink_trace_drr_table_status.csv is old, last update: ${extracted_date}."
fi

# secondary accession type
extracted_date=$(ls -l --time-style=full-iso /home/systool/DBLINK_DDBJ/dblink_ddbj_standby/tsunami/table_accession_type.csv | cut -f6 -d" " )
if [[ "$extracted_date" = "$current_date" ]]; then
  log "Uploading accession_type"
  psql -d ${db} -c "DROP TABLE accession_type; "
  psql -d ${db} -c "CREATE TABLE accession_type(
    id_sec_acc SERIAL,
    accession VARCHAR(20) NOT NULL,
    type VARCHAR(3) NOT NULL,
    PRIMARY KEY (id_sec_acc,accession)
    ); "
  psql -d ${db} -c "COPY accession_type(accession,type)
  FROM '/home/systool/DBLINK_DDBJ/dblink_ddbj_standby/tsunami/table_accession_type.csv'
  DELIMITER ',';"
else
  log "File table_accession_type.csv is old, last update: ${extracted_date}."
fi

# relation primary2secondary accession 
extracted_date=$(ls -l --time-style=full-iso /home/systool/DBLINK_DDBJ/dblink_ddbj_standby/tsunami/table_accession_current2obsolete.csv | cut -f6 -d" " )
if [[ "$extracted_date" = "$current_date" ]]; then
  log "Uploading rel_pri2sec"
  psql -d ${db} -c "DROP TABLE rel_pri2sec; "
  psql -d ${db} -c "CREATE TABLE rel_pri2sec(
    id_pri2sec SERIAL,
    accession VARCHAR(20) NOT NULL,
    accession2 VARCHAR(20) NOT NULL,  
    PRIMARY KEY (id_pri2sec,accession,accession2)
    ); "
  psql -d ${db} -c "COPY rel_pri2sec(accession,accession2)
  FROM '/home/systool/DBLINK_DDBJ/dblink_ddbj_standby/tsunami/table_accession_current2obsolete.csv'
  DELIMITER ',';"
else
  log "File table_accession_current2obsolete.csv is old, last update: ${extracted_date}."
fi

log "Script finished"

# sh ~/.per/addp.sh
psql -d ${db} -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO public;"
# db2="dblink_ddbj_standby"
#psql -d ${db2} -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO public;"