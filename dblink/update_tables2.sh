#!/bin/bash
############################################################################
# dblink_ddbj
############################################################################
# Developed by Andrea Ghelfi 
# 2025.4.4 Updated by Andrea Ghelfi (2025 new supercomputer settings)
# 2025.10.24 Updated not to import from UMSS data tables (umss is discontinued,
# https://ddbj-dev.atlassian.net/browse/DB-1508).
############################################################################

# dir="/home/andrea/projects/dblink_ddbj/dblink_ddbj_devel/"
# scripts="/home/andrea/scripts/"
BASE="/home/w3const/work-kosuge/dblink"
# PG user for project,sample,dor,drm
PG_USER1="const"
# PG user for g-,e-,w-actual
PG_USER2="tkosuge"

mkdir -p ${BASE}/dblink_ddbj_devel ${BASE}/dblink_ddbj_standby
mkdir -p \
${BASE}/dblink_ddbj_devel/gea \
${BASE}/dblink_ddbj_devel/trace \
${BASE}/dblink_ddbj_devel/trace/sra \
${BASE}/dblink_ddbj_devel/tsunami \
${BASE}/dblink_ddbj_devel/tsunami/temp \
${BASE}/dblink_ddbj_standby/gea \
${BASE}/dblink_ddbj_standby/trace \
${BASE}/dblink_ddbj_standby/tsunami

# LOGFILE="/home/andrea/projects/dblink_ddbj/dblink_ddbj_devel/update_tables.log"
LOGFILE="${BASE}/dblink_ddbj_devel/update_tables.log"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOGFILE" 2>&1
}

log "Update tables started"

dir="${BASE}/dblink_ddbj_devel/"
scripts=${BASE}/
export PGPASSFILE=${BASE}/.pgpass

cd ${dir}gea
rm -f test_gea.txt
HOST="a011"
PGPORT=54301
PGDATABASE="dordb"
psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -w -t -A -F"," -c "SELECT version();" --set=statement_timeout=1 > test_gea.txt
if [ -f test_gea.txt ]; then
    len_test_gea=` fgrep "PostgreSQL" test_gea.txt | wc -l `
    if [[ ${len_test_gea} -eq 1 ]]; then
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT ac.accession, cor.submission_id, css.submission_status_type FROM mass.accession ac JOIN mass.current_object_relation cor USING(accession_id) JOIN mass.current_submission_status css ON(css.submission_id=cor.submission_id) WHERE ac.accession_type IN (1,11,12) AND ac.accession IS NOT NULL ;" > table_gea_bp_bs.txt
        awk -F"," '$1~"GEAD" {print $0}' table_gea_bp_bs.txt > gea_submission_id.csv
        awk -F"," -v OFS="," '$1~"PRJD" {print $1,$2}' table_gea_bp_bs.txt > bp_submission_id.csv
        awk -F"," -v OFS="," '$1~"SAM" {print $1,$2}' table_gea_bp_bs.txt > gea_bs_submission_id.csv
        Rscript ${scripts}gea.R || { log "R script gea failed"; exit 1; }
    else
        log "Can't connect with dordb."
    fi
else
    log "File test_gea.txt do not exist."
fi

# trad
cd ${dir}tsunami
rm -f test_at102.txt

HOST="a011"
PGPORT=54303
PGDATABASE="g-actual"
psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT version();" --set=statement_timeout=1 > test_at102.txt
if [ -f test_at102.txt ]; then
    len_test_at102=` fgrep "PostgreSQL" test_at102.txt | wc -l `
    if [[ ${len_test_at102} -eq 1 ]]; then
        log "Tsunami: job started"
        rm -rf temp/
        mkdir -p temp/
        # at102
        ## MAIN TABLE; added count using awk
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT translate(acc.accession,' ',''),project.project_id,source.ut_id AS tax_id, man.status, DATE(man.accept_date) AS accept_date FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) JOIN source ON(source.ac_id=acc.ac_id) JOIN manager AS man ON(man.ac_id=acc.ac_id) WHERE project.project_id LIKE 'PRJD%' AND (acc.accession ~ '^B[A-Z][0-9]') UNION SELECT translate(acc.accession,' ',''),project.project_id,source.ut_id AS tax_id, man.status, DATE(man.accept_date) AS accept_date FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) JOIN source ON(source.ac_id=acc.ac_id) JOIN manager AS man ON(man.ac_id=acc.ac_id) WHERE project.project_id LIKE 'PRJD%' AND (acc.accession NOT LIKE 'B%') ;" | awk '{print $0",1"}' > temp/at102_bioproject_accept_date.txt
        #pid_at102=$!
        ## accession without bioproject and has secondary accession
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT translate(acc.accession,' ',''), COALESCE(NULLIF(project.project_id, ''), 'NA') AS project, source.ut_id AS tax_id, man.status, DATE(man.accept_date) AS accept_date FROM accession AS acc LEFT OUTER JOIN link_pr_ac USING(ac_id) LEFT OUTER JOIN project ON(project.pr_id=link_pr_ac.pr_id) LEFT OUTER JOIN source ON(source.ac_id=acc.ac_id) LEFT OUTER JOIN manager AS man ON(man.ac_id=acc.ac_id) LEFT OUTER JOIN dataflow AS df ON (acc.ac_id=df.ac_id) WHERE (df.status = 1049 OR df.status = 1052) AND (acc.accession ~ '^B[A-Z][0-9]') UNION SELECT DISTINCT translate(acc.accession,' ',''), COALESCE(NULLIF(project.project_id, ''), 'NA') AS project, source.ut_id AS tax_id, man.status, DATE(man.accept_date) AS accept_date FROM accession AS acc LEFT OUTER JOIN link_pr_ac USING(ac_id) LEFT OUTER JOIN project ON(project.pr_id=link_pr_ac.pr_id) LEFT OUTER JOIN source ON(source.ac_id=acc.ac_id) LEFT OUTER JOIN manager AS man ON(man.ac_id=acc.ac_id) LEFT OUTER JOIN dataflow AS df ON (acc.ac_id=df.ac_id) WHERE (df.status = 1049 OR df.status = 1052) AND (acc.accession NOT LIKE 'B%') ;" > temp/at102_has2nd_accession_accept_date.txt
        # Table to correlate current to obsolete
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT acc.ac_id, SUBSTRING(acc.accession, 1, 6) AS prefix, df.status AS df_status FROM accession AS acc LEFT OUTER JOIN manager AS man ON(man.ac_id=acc.ac_id) LEFT OUTER JOIN dataflow AS df ON (acc.ac_id=df.ac_id) WHERE (df.status = 1049 OR df.status = 1052) AND (acc.accession ~ '^B[A-Z][A-Z][A-Z]') UNION SELECT acc.ac_id, translate(acc.accession,' ',''), df.status AS df_status FROM accession AS acc LEFT OUTER JOIN manager AS man ON(man.ac_id=acc.ac_id) LEFT OUTER JOIN dataflow AS df ON (acc.ac_id=df.ac_id) WHERE (df.status = 1049 OR df.status = 1052) AND NOT (acc.accession ~ '^B[A-Z][A-Z][A-Z]') ;" > temp/at102_rel2nd_accession.txt
        # pid_rel102=$!
    else
        log "Can't connect with g-actual."
    fi
else
    log "File test_at102.txt do not exist."
fi

PGPORT=54304
PGDATABASE="e-actual"
rm -f test_at101.txt
psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT version();" --set=statement_timeout=1 > test_at101.txt
if [ -f test_at101.txt ]; then
    len_test_at101=` fgrep "PostgreSQL" test_at101.txt | wc -l `
    if [[ ${len_test_at101} -eq 1 ]]; then
        # at101
        ## MAIN TABLE; added count using awk for prefix other than T* or I*
        cd ${dir}tsunami
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT SUBSTRING(acc.accession, 1, 6) AS prefix,project.project_id,source.ut_id AS tax_id, man.status, DATE(man.accept_date) AS accept_date, COUNT(*) AS count FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) JOIN source ON(source.ac_id=acc.ac_id) JOIN manager AS man ON(man.ac_id=acc.ac_id) WHERE project.project_id LIKE 'PRJD%' AND (acc.accession LIKE 'T%' OR acc.accession LIKE 'I%') GROUP BY (SUBSTRING(acc.accession, 1, 6),project.project_id,source.ut_id, man.status, DATE(man.accept_date));" > temp/at101_bioproject_prefix_TI_accept_date.txt
        # pid_at101t=$! 
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT translate(acc.accession,' ',''),project.project_id,source.ut_id AS tax_id, man.status, DATE(man.accept_date) AS accept_date FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) JOIN source ON(source.ac_id=acc.ac_id) JOIN manager AS man ON(man.ac_id=acc.ac_id) WHERE project.project_id LIKE 'PRJD%' AND NOT (acc.accession LIKE 'T%' OR acc.accession LIKE 'I%') ; " | awk '{print $0",1"}' > temp/at101_bioproject_prefix_other_accept_date.txt
        # pid_at101=$! 
        ## accession without bioproject and has secondary accession
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT translate(acc.accession,' ',''), COALESCE(NULLIF(project.project_id, ''), 'NA') AS project, source.ut_id AS tax_id, man.status, DATE(man.accept_date) AS accept_date FROM accession AS acc LEFT OUTER JOIN link_pr_ac USING(ac_id) LEFT OUTER JOIN project ON(project.pr_id=link_pr_ac.pr_id) LEFT OUTER JOIN source ON(source.ac_id=acc.ac_id) LEFT OUTER JOIN manager AS man ON(man.ac_id=acc.ac_id) LEFT OUTER JOIN dataflow AS df ON (acc.ac_id=df.ac_id) WHERE (df.status = 1049 OR df.status = 1052) AND NOT (acc.accession LIKE 'T%' OR acc.accession LIKE 'I%') ;" > temp/at101_has2nd_accession_accept_date.txt & 
        # Table to correlate current to obsolete; attention periodically check if there are any Prefix T* or I* in this list
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT acc.ac_id, SUBSTRING(acc.accession, 1, 6) AS prefix, df.status AS df_status FROM accession AS acc LEFT OUTER JOIN manager AS man ON(man.ac_id=acc.ac_id) LEFT OUTER JOIN dataflow AS df ON (acc.ac_id=df.ac_id) WHERE (df.status = 1049 OR df.status = 1052) AND (acc.accession LIKE 'T%' OR acc.accession LIKE 'I%') UNION SELECT acc.ac_id, translate(acc.accession,' ',''), df.status AS df_status FROM accession AS acc LEFT OUTER JOIN manager AS man ON(man.ac_id=acc.ac_id) LEFT OUTER JOIN dataflow AS df ON (acc.ac_id=df.ac_id) WHERE (df.status = 1049 OR df.status = 1052) AND NOT (acc.accession LIKE 'T%' OR acc.accession LIKE 'I%') ;" > temp/at101_rel2nd_accession.txt 
        # pid_rel101=$! 
        # at101 umss, discontinued since 2025.10
        # psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT ut_id,prefix,set_version,ann_val_common FROM umss_ann_common ;" > temp/at101_umss_dblink_taxid.txt
        # psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT prefix,set_version,status,accept_date FROM umss_ann_entry ;" > temp/at101_umss_dblink_status.txt
    else
        log "Can't connect with e-actual."
    fi
else
    log "File test_at101.txt do not exist."
fi
PGPORT=54305
PGDATABASE="w-actual"
rm -f test_at103.txt
psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT version();" --set=statement_timeout=1 > test_at103.txt
if [ -f test_at103.txt ]; then
    len_test_at103=` fgrep "PostgreSQL" test_at103.txt | wc -l `
    if [[ ${len_test_at103} -eq 1 ]]; then
        # at103
        ## MAIN TABLE; added count using awk for prefix other than B* or E* or Y*
        cd ${dir}tsunami
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT CASE
                WHEN LENGTH(acc.accession) > 13 THEN LEFT(acc.accession, 8)
                WHEN LENGTH(acc.accession) <= 13 THEN LEFT(acc.accession, 6)
            END AS prefix,project.project_id,source.ut_id AS tax_id, man.status, DATE(man.accept_date) AS accept_date, COUNT(*) AS count FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) JOIN source ON(source.ac_id=acc.ac_id) JOIN manager AS man ON(man.ac_id=acc.ac_id) WHERE project.project_id LIKE 'PRJD%' AND (acc.accession LIKE 'B%' OR acc.accession LIKE 'E%' OR acc.accession LIKE 'Y%') GROUP BY (prefix,project.project_id,source.ut_id, man.status, DATE(man.accept_date));" > temp/at103_bioproject_prefix_BEY_accept_date.txt
        # pid_at103b=$!
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT translate(acc.accession,' ',''),project.project_id,source.ut_id AS tax_id, man.status, DATE(man.accept_date) AS accept_date FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) JOIN source ON(source.ac_id=acc.ac_id) JOIN manager AS man ON(man.ac_id=acc.ac_id) WHERE project.project_id LIKE 'PRJD%' AND NOT (acc.accession LIKE 'B%' OR acc.accession LIKE 'E%' OR acc.accession LIKE 'Y%') ; " | awk '{print $0",1"}' > temp/at103_bioproject_prefix_other_accept_date.txt
        # pid_at103=$!
        # at103 umss, discontinued since 2025.10
        # psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT ut_id,prefix,set_version,ann_val_common FROM umss_ann_common ;" > temp/at103_umss_dblink_taxid.txt
        # psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT prefix,set_version,status,accept_date FROM umss_ann_entry ;" > temp/at103_umss_dblink_status.txt
    else
        log "Can't connect with w-actual."
    fi
else
    log "File test_at103.txt do not exist."
fi

if [[ ${len_test_at101} -eq 1 && ${len_test_at102} -eq 1 && ${len_test_at103} -eq 1 ]]; then
    # wait ${pid_rel101} ${pid_rel102}
    log "Tsunami: building tables bioproject"
    Rscript ${scripts}primary2secondary.R || { log "R script primary2 failed"; exit 1; }
    # wait ${pid_at102} ${pid_at101t} ${pid_at101} ${pid_at103b} ${pid_at103}
    cat temp/at103_bioproject_*accept_date.txt | awk -v OFS="," '{print "w-actual",$0}' > bp_w_actual.txt
    cat temp/at102_bioproject_*accept_date.txt | awk -v OFS="," '{print "g-actual",$0}' > bp_g_actual.txt
    cat temp/at101_bioproject_*accept_date.txt | awk -v OFS="," '{print "e-actual",$0}' > bp_e_actual.txt
    # umss, discontinued since 2025.10
    # awk -F"\t" -v OFS="," '{if($1 ~ "COMMON"){accession = $1; version=$2}; if($4 == "project") {print accession,version, $5}}' temp/at103_umss_dblink_taxid.txt | awk -F"," -v OFS="," '{gsub(" ","");print $2,$3,$6,$1}' | awk '{sub(",","");print "umss-w," $0}' | awk -F"," -v OFS="," '{ if ($4=="") print $0"0" ; else print $0}' > temp/at103_umss_dblink_taxid_clean.txt
    # awk '{gsub(" ",""); sub(",",""); print $0}' temp/at103_umss_dblink_status.txt > temp/at103_umss_dblink_status_clean.txt
    # awk -F"\t" -v OFS="," '{if($1 ~ "COMMON"){accession = $1; version=$2}; if($4 == "project") {print accession,version, $5}}' temp/at101_umss_dblink_taxid.txt  | awk -F"," -v OFS="," '{gsub(" ","");print $2,$3,$6,$1}' | awk '{sub(",","");print "umss-e," $0}' | awk -F"," -v OFS="," '{ if ($4=="") print $0"0" ; else print $0}' > temp/at101_umss_dblink_taxid_clean.txt
    # awk '{gsub(" ",""); sub(",",""); print $0}' temp/at101_umss_dblink_status.txt > temp/at101_umss_dblink_status_clean.txt
    # Rscript ${scripts}edit_umss.R || { log "R script edit failed"; exit 1; }
    Rscript ${scripts}filter_has2nd_accession.R || { log "R script filter failed"; exit 1; }
    cat bp_*_actual.txt > ../../dblink_ddbj_standby/tsunami/bp_actual_taxon.csv
    # Add BioSample and DRR tables
    # at103 (w-actual)

    # add set_id for 6 characters accessions
    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT CASE
                WHEN LENGTH(acc.accession) > 13 THEN LEFT(acc.accession, 8)
                WHEN LENGTH(acc.accession) <= 13 THEN LEFT(acc.accession, 6)
            END AS prefix,project.project_id FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'SAMD%' AND  (acc.accession LIKE 'B%' OR acc.accession LIKE 'E%' OR acc.accession LIKE 'Y%'); " > temp/at103_biosample_prefix_BEY.txt
    # pid_at103a=$!

    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT CASE
                WHEN LENGTH(acc.accession) > 13 THEN LEFT(acc.accession, 8)
                WHEN LENGTH(acc.accession) <= 13 THEN LEFT(acc.accession, 6)
            END AS prefix,project.project_id FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'DRR%' AND  (acc.accession LIKE 'B%' OR acc.accession LIKE 'E%' OR acc.accession LIKE 'Y%'); " > temp/at103_drr_prefix_BEY.txt
    # pid_at103b=$!

    # other prefixes not B,E,Y
    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT translate(accession.accession,' ',''),project.project_id FROM accession JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'SAMD%' AND (accession.accession NOT LIKE 'B%' AND accession.accession NOT LIKE 'E%' AND accession.accession NOT LIKE 'Y%'); " > temp/at103_biosample_prefix_other.txt
    # pid_at103c=$!

    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT translate(accession.accession,' ',''),project.project_id FROM accession JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'DRR%' AND (accession.accession NOT LIKE 'B%' AND accession.accession NOT LIKE 'E%' AND accession.accession NOT LIKE 'Y%'); " > temp/at103_drr_prefix_other.txt
    # pid_at103d=$!
    # at101 (e-actual)
    # prefixes: T,I
    PGPORT=54304
    PGDATABASE="e-actual"

    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT CASE
                WHEN LENGTH(acc.accession) > 13 THEN LEFT(acc.accession, 8)
                WHEN LENGTH(acc.accession) <= 13 THEN LEFT(acc.accession, 6)
            END AS prefix,project.project_id FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'SAMD%' AND (acc.accession LIKE 'T%' OR acc.accession LIKE 'I%'); " > temp/at101_biosample_prefix_TI.txt
    # pid_at101a=$!
    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT CASE
                WHEN LENGTH(acc.accession) > 13 THEN LEFT(acc.accession, 8)
                WHEN LENGTH(acc.accession) <= 13 THEN LEFT(acc.accession, 6)
            END AS prefix,project.project_id FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'DRR%' AND (acc.accession LIKE 'T%' OR acc.accession LIKE 'I%'); " > temp/at101_drr_prefix_TI.txt
    # pid_at101b=$!
    # other prefixes not T,I
    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT translate(accession.accession,' ',''),project.project_id FROM accession JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'SAMD%' AND (accession.accession NOT LIKE 'T%' AND accession.accession NOT LIKE 'I%'); " > temp/at101_biosample_prefix_other.txt
    # pid_at101c=$!
    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT translate(accession.accession,' ',''),project.project_id FROM accession JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'DRR%' AND (accession.accession NOT LIKE 'T%' AND accession.accession NOT LIKE 'I%'); " > temp/at101_drr_prefix_other.txt
    # pid_at101d=$!
    # at102 (g-actual)
    PGPORT=54303
    PGDATABASE="g-actual"
    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT CASE
                WHEN LENGTH(acc.accession) > 13 THEN LEFT(acc.accession, 8)
                WHEN LENGTH(acc.accession) <= 13 THEN LEFT(acc.accession, 6)
            END AS prefix,project.project_id FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'SAMD%' AND (acc.accession LIKE 'B%' AND acc.accession ~ 'B[A-Z][A-Z]') ; " > temp/at102_biosample_prefix_B.txt
    # pid_at102a=$!
    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT DISTINCT CASE
                WHEN LENGTH(acc.accession) > 13 THEN LEFT(acc.accession, 8)
                WHEN LENGTH(acc.accession) <= 13 THEN LEFT(acc.accession, 6)
            END AS prefix,project.project_id FROM accession AS acc JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'DRR%' AND (acc.accession LIKE 'B%' AND acc.accession ~ 'B[A-Z][A-Z]') ; " > temp/at102_drr_prefix_B.txt
    # pid_at102b=$!
    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT translate(accession.accession,' ',''),project.project_id FROM accession JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'SAMD%' AND (accession.accession ~ '^B[A-Z][0-9]' ) UNION SELECT translate(accession.accession,' ',''),project.project_id FROM accession JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'SAMD%' AND (accession.accession NOT LIKE 'B%' ) ;" > temp/at102_biosample_prefix_other.txt
    # pid_at102c=$!
    psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER2} -t -A -F"," -c "SELECT translate(accession.accession,' ',''),project.project_id FROM accession JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'DRR%' AND (accession.accession ~ '^B[A-Z][0-9]' ) UNION SELECT translate(accession.accession,' ',''),project.project_id FROM accession JOIN link_pr_ac USING(ac_id) JOIN project ON(project.pr_id=link_pr_ac.pr_id) WHERE project.project_id LIKE 'DRR%' AND (accession.accession NOT LIKE 'B%' ) ;" > temp/at102_drr_prefix_other.txt
    # pid_at102d=$!
    # edit
    # wait ${pid_at101a} ${pid_at101b} ${pid_at101c} ${pid_at101d} ${pid_at102a} ${pid_at102b} ${pid_at102c} ${pid_at102d} ${pid_at103a} ${pid_at103b} ${pid_at103c} ${pid_at103d} 
    log "Tsunami: building tables biosample"
    cat temp/at103_biosample_prefix_*.txt > biosample_w_actual.txt
    cat temp/at102_biosample_prefix_*.txt > biosample_g_actual.txt
    cat temp/at101_biosample_prefix_*.txt > biosample_e_actual.txt
    cat temp/at103_drr_prefix_*.txt > drr_w_actual.txt
    cat temp/at102_drr_prefix*.txt > drr_g_actual.txt
    cat temp/at101_drr_prefix*.txt > drr_e_actual.txt
    # umss biosample, discontinued since 2025.10
    # awk -F"\t" -v OFS="," '{if($1 ~ "COMMON"){accession = $1; version=$2}; if($4 == "biosample") {print accession,version, $5}}' temp/at103_umss_dblink_taxid.txt | awk -F"," -v OFS="," '{gsub(" ","");print $2,$3,$6}' | awk '{sub(",","");print $0}' > biosample_umssw_actual.txt
    # awk -F"\t" -v OFS="," '{if($1 ~ "COMMON"){accession = $1; version=$2}; if($4 == "biosample") {print accession,version, $5}}' temp/at101_umss_dblink_taxid.txt  | awk -F"," -v OFS="," '{gsub(" ","");print $2,$3,$6}' | awk '{sub(",","");print $0}' > biosample_umsse_actual.txt
    # umss sra, discontinued since 2025.10
    # awk -F"\t" -v OFS="," '{if($1 ~ "COMMON"){accession = $1; version=$2}; if($4 == "sequence read archive") {print accession,version, $5}}' temp/at103_umss_dblink_taxid.txt | awk -F"," -v OFS="," '{gsub(" ","");print $2,$3,$6}' | awk '{sub(",","");print $0}' > drr_umssw_actual.txt
    # awk -F"\t" -v OFS="," '{if($1 ~ "COMMON"){accession = $1; version=$2}; if($4 == "sequence read archive") {print accession,version, $5}}' temp/at101_umss_dblink_taxid.txt  | awk -F"," -v OFS="," '{gsub(" ","");print $2,$3,$6}' | awk '{sub(",","");print $0}' > drr_umsse_actual.txt
    #
    cat biosample_*_actual.txt > ../../dblink_ddbj_standby/tsunami/biosample_actual.csv
    cat drr_*_actual.txt > ../../dblink_ddbj_standby/tsunami/drr_actual.csv
    log "Tsunami: job finished"
else
    log "Can't connect with TsunamiDB."
fi
#
cd ${dir}trace
rm -rf test_trace.txt sra/
mkdir -p sra/
PGPORT=54301
PGDATABASE="drmdb"
psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -w -t -A -F"," -c "SELECT version();" --set=statement_timeout=1 > test_trace.txt
if [ -f test_trace.txt ]; then
    len_test_trace=` fgrep "PostgreSQL" test_trace.txt | wc -l `
    if [[ ${len_test_trace} -eq 1 ]]; then
        log "Trad: job started"
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT ext_ent.acc_type, ext_ent.ref_name, drx_ent.acc_type, drx_ent.acc_no, sub_grpv.status \
        FROM mass.ext_entity ext_ent \
        JOIN mass.ext_relation ext_rel USING(ext_id) \
        JOIN mass.accession_entity drx_ent USING(acc_id)
        JOIN mass.current_dra_submission_group_view sub_grpv USING(grp_id) \
        WHERE drx_ent.acc_no IS NOT NULL ;" > sra/drmdb.drx_status.csv &
        pid_drx=$!
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT ext_ent.acc_type, ext_ent.ref_name, drr_ent.acc_type, drr_ent.acc_no, sub_grpv.status \
        FROM mass.ext_entity ext_ent \
        JOIN mass.ext_relation ext_rel USING(ext_id) \
        JOIN mass.accession_entity drx_ent ON(ext_rel.acc_id = drx_ent.acc_id) \
        JOIN mass.accession_relation drx_drr_rel ON(drx_ent.acc_id=drx_drr_rel.p_acc_id) \
        JOIN mass.accession_entity drr_ent ON(drx_drr_rel.acc_id=drr_ent.acc_id) \
        JOIN mass.current_dra_submission_group_view sub_grpv ON(drx_drr_rel.grp_id=sub_grpv.grp_id) \
        WHERE drr_ent.acc_type='DRR' AND drx_drr_rel.grp_id=ext_rel.grp_id AND drr_ent.acc_no IS NOT NULL ;" > sra/drmdb.drr_status.csv &
        pid_drr=$!
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT alias,acc_type,acc_no FROM mass.accession_entity ent WHERE is_delete='f' ; " > sra/trace_alias_dra_drx_drr.csv &
        pid_dra=$!
        # add information of 'is_delete' from table mass.accession_entity from trace_alias_dra_drx_drr.csv.
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT submitter_id,submission_id,accession,status FROM mass.dra_summary WHERE status NOT IN (1000, 1100, 1200) ; " > sra/trace_alias_status.csv &
        pid_alias=$!        
        # BioProject
        PGDATABASE="bioproject"
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT submitter_id,p.submission_id,p.project_id_prefix,p.project_id_counter,p.status_id,project_type,sd.data_value FROM mass.project p JOIN mass.submission s USING(submission_id) JOIN mass.submission_data sd ON (sd.submission_id=p.submission_id) WHERE sd.data_name='locus_tag' AND COALESCE(p.project_id_prefix, '') != '' ; " > sra/bpDB_submitter_locus_tag.csv
        # BioSampleDB: bioproject_id -> smp_id
        PGDATABASE="biosample"
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT smp_id,attribute_value FROM mass.attribute WHERE attribute_name='bioproject_id' AND attribute_value LIKE 'PRJD%' ; " > sra/bsDB_bioproject_smp_id.csv
        awk -F"," '{gsub(", ", "\n"$1","); print $0}' sra/bsDB_bioproject_smp_id.csv > sra/edited_bsDB_bioproject_smp_id.csv
        # BioSampleDB:locus_tag
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT attribute_value,smp_id FROM mass.attribute WHERE attribute_name='locus_tag_prefix' AND COALESCE(attribute_value, '') != '' AND attribute_value != 'N.A.' AND attribute_value != 'not applicable' ; " > sra/bsDB_locus_tag_smp_id.csv
        # BioSampleDB:organism
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT attribute_value,smp_id FROM mass.attribute WHERE attribute_name='taxonomy_id';" > sra/temp_bsDB_taxon_smp_id.csv
        grep -i -v "[a-z]" sra/temp_bsDB_taxon_smp_id.csv > sra/bsDB_taxon_smp_id.csv
        # BioSampleDB: smp_id -> accession_id (biosample_id)
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT accession_id,smp_id FROM mass.biosample_summary WHERE entity_status !=0 ; " > sra/bsDB_biosample_smp_id.csv
        # BioSampleDB: submitter,status
        psql -h $HOST -p $PGPORT -d $PGDATABASE -U ${PG_USER1} -t -A -F"," -c "SELECT submitter_id,submission_id,status_id,smp_id FROM mass.sample sam JOIN mass.submission sub USING(submission_id) ;" > sra/bsDB_submitter_status_smp_id.csv
        wait ${pid_drx} ${pid_drr} ${pid_dra} ${pid_alias}
        log "Trad: Start building tables"
        Rscript ${scripts}trace_bp.R || { echo "R script trace_bp failed"; exit 1; }
        Rscript ${scripts}trace_drr.R || { echo "R script trace_drr failed"; exit 1; }
        log "Trad: job finished"
    else
    log "Can't connect with TradDBs."
    fi
else
    log "File test_trace.txt do not exist."
fi
