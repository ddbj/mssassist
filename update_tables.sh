#!/bin/bash
############################################################################
# update_tables
############################################################################
# Developed by Andrea Ghelfi 
# Updated by Andrea Ghelfi 2025.3.20 (2025 new supercomputer settings)
# This script update tables required by ddbj_mss_validation and ddbj_autofix.
# Usage: bash /home/andrea/scripts/update_tables.sh
############################################################################

BASE="/home/w3const/mssassist"
export PGUSER="const"
export PGPASSWORD="const"
LOGFILE="${BASE}/tables/update_tables.log"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOGFILE" 2>&1
}

log "Update tables started"

cd ${BASE}/tables/
HOST="a011"
# HOST="a012"
PGPORT=54301
PGDATABASE="biosample"

psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT * FROM mass.accession limit 10;" > biosample.test.connection.csv
length=`wc -l biosample.test.connection.csv | cut -f1 -d" "`
if [ $length -gt 0 ]; then
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT bios_summary.submission_id, bios_summary.accession_id, bios_summary.smp_id, contact.email, contact.first_name, contact.last_name, bios_summary.entity_status \
  FROM mass.contact contact \
  JOIN mass.biosample_summary bios_summary USING(submission_id) \
  WHERE bios_summary.entity_status!=0;" > biosample.biosample_summary2.csv; # remove null biosample_id
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT smp_id,status_id FROM mass.sample WHERE status_id=5400 OR status_id=5500 OR status_id=5300;" > biosample.sample.status_id.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT attribute_name,attribute_value,smp_id FROM mass.attribute WHERE attribute_name='organism';" > biosample.organism.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT attribute_name,attribute_value,smp_id FROM mass.attribute WHERE attribute_name='isolate';" > biosample.isolate.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT attribute_name,attribute_value,smp_id FROM mass.attribute WHERE attribute_name='strain';" > biosample.strain.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT attribute_name,attribute_value,smp_id FROM mass.attribute WHERE attribute_name='cultivar';" > biosample.cultivar.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT * FROM mass.attribute WHERE attribute_name='locus_tag_prefix' ;" > biosample.attribute_name_locus_tag_prefix.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"," -c "SELECT * FROM mass.attribute WHERE attribute_name='bioproject_id' ;" > biosample.attribute_name_bioproject.csv; # table 1/3; complement this table with sra and locus_tag prefix
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT attribute_name,attribute_value,smp_id FROM mass.attribute WHERE attribute_name='host' ;" > biosample.attribute_name_host.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"," -c "SELECT accession_id,smp_id FROM mass.accession;" > biosample.accession.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT attribute_value,smp_id FROM mass.attribute WHERE attribute_name='collection_date';" > biosample.collection_date.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT attribute_value,smp_id FROM mass.attribute WHERE attribute_name='isolation_source';" | awk -F"|" '$1!="" {print}' > biosample.isolation_source.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT * FROM mass.attribute WHERE attribute_name='geo_loc_name' ;" > biosample.attribute_name_geo_loc_name.csv;
  
  PGDATABASE="bioproject"
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT submission_id,data_value FROM mass.submission_data WHERE data_name='email' ;" > bioproject.submission_data_email.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"|" -c "SELECT submission_id,data_value FROM mass.submission_data WHERE data_name='locus_tag' ;" > bioproject.submission_data_locus_tag.csv;
  # updated command line: implemented status_id and project_type = primary
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"," -c "SELECT submission_id,project_id_prefix,project_id_counter,project_type FROM mass.project WHERE project_id_prefix='PRJDB' AND (status_id=5400 OR status_id=5500 OR status_id=5300) AND project_type='primary';" > bioproject.csv;
  # edit tables
  egrep -v "missing:" biosample.collection_date.csv | awk -F"|" '$1!="" {gsub("\"",""); print}' > clean_biosample.collection_date.csv;
  awk -F"|" '$3!="" {print}' biosample.attribute_name_locus_tag_prefix.csv > clean_biosample.attribute_name_locus_tag_prefix.csv;
  awk -F"|" '$2!="" {print}' biosample.strain.csv > clean_biosample.strain.csv;
  awk -F"|" '$2!="" {print}' biosample.isolate.csv > clean_biosample.isolate.csv;
  awk -F"|" '$2!="" {print}' biosample.cultivar.csv > clean_biosample.cultivar.csv;
  awk -F"|" '$2!="" {print}' bioproject.submission_data_locus_tag.csv > clean_bioproject.submission_data_locus_tag.csv;
  awk -F"|" '$2!="" {print}' biosample.attribute_name_host.csv > clean_biosample.attribute_name_host.csv;
  egrep -i "prjd" biosample.attribute_name_bioproject.csv | cut -f3- -d"," > temp_bp2smp_id.csv; 
  rev temp_bp2smp_id.csv | awk -F"," '{print $0, $1}' |rev | awk '{gsub(",", "_"$1"|");print}' | awk '{gsub(" ","\n"); gsub("[|]","\n"); print}' | egrep -i "prjdb" | awk '{sub("_", "\t"); print}'> bp2smp_id.csv;
  egrep -v "missing:" biosample.attribute_name_geo_loc_name.csv | awk '{gsub("\"",""); print}' > clean_biosample.attribute_name_geo_loc_name.csv;

  PGDATABASE="drmdb"
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"," -c "SELECT ext_ent.acc_type, ext_ent.ref_name, drx_ent.acc_type, drx_ent.acc_no \
    FROM mass.ext_entity ext_ent \
    JOIN mass.ext_relation ext_rel USING(ext_id) \
    JOIN mass.accession_entity drx_ent USING(acc_id)
    JOIN mass.current_dra_submission_group_view sub_grpv USING(grp_id) \
    WHERE (sub_grpv.status IS NULL OR sub_grpv.status NOT IN (1000, 1100, 1200));" > drmdb.drx.csv;
  psql -U ${PGUSER} -d $PGDATABASE -h $HOST --port=$PGPORT -t -A -F"," -c "SELECT ext_ent.acc_type, ext_ent.ref_name, drr_ent.acc_type, drr_ent.acc_no \
    FROM mass.ext_entity ext_ent \
    JOIN mass.ext_relation ext_rel USING(ext_id) \
    JOIN mass.accession_entity drx_ent ON(ext_rel.acc_id = drx_ent.acc_id) \
    JOIN mass.accession_relation drx_drr_rel ON(drx_ent.acc_id=drx_drr_rel.p_acc_id) \
    JOIN mass.accession_entity drr_ent ON(drx_drr_rel.acc_id=drr_ent.acc_id) \
    JOIN mass.current_dra_submission_group_view sub_grpv ON(drx_drr_rel.grp_id=sub_grpv.grp_id) \
    WHERE drr_ent.acc_type='DRR' AND drx_drr_rel.grp_id=ext_rel.grp_id AND (sub_grpv.status IS NULL OR sub_grpv.status NOT IN (1000, 1100, 1200));" > drmdb.drr.csv;
  log "Database query executed successfully."
  awk -F"," -v OFS="\t" '($4 != "" && $1=="SSUB"){print $2,$3$4}' drmdb.drr.csv > drmdb.smp2drr.csv;
  awk -F"," -v OFS="\t" '($4 != "" && $1=="PSUB"){print $2,$3$4}' drmdb.drr.csv > drmdb.psub2drr.csv;
  awk -F"," -v OFS="\t" '($3 != "" && $4 != "" ){print $1,$2$3, $4}' bioproject.csv > bioproject.psub2prjd.csv;
  
  log "Executing Rscript..."
    Rscript ${BASE}/update_tables.R >> "$LOGFILE" 2>&1
    if [ $? -eq 0 ]; then
        log "Rscript executed successfully."
    else
        log "Error: Rscript execution failed."
    fi
    rm drmdb.drr.csv biosample.biosample_summary2.csv biosample.attribute_name_host.csv bioproject.submission_data_locus_tag.csv biosample.cultivar.csv biosample.isolate.csv biosample.strain.csv biosample.attribute_name_locus_tag_prefix.csv biosample.collection_date.csv biosample.attribute_name_geo_loc_name.csv biosample.attribute_name_bioproject.csv temp_bp2smp_id.csv bioproject.csv

  else
    log "Error: Database query failed."  
fi

log "Script finished"
