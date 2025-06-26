# mssassist
Validation, correction, and data registration scripts to assist MSS work

I have taken Andrea-san mss fix tools, and will migrate them here.
Takehide Kosuge

# Add the followings to cron@a012
~~~
# MSS ddbj_mss_validation
0 8 * * *  bash /home/w3const/mssassist/update_taxdump.sh
0 8,10,12,14,16,18 * * * bash /home/w3const/mssassist/update_tables.sh
~~~
