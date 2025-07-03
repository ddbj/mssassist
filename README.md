# mssassist
Validation, correction, and data registration scripts to assist MSS work

I have taken Andrea-san mss fix tools, and will migrate them here.
Takehide Kosuge

# Installation
1. Pull the repository from ddbj/mssassist.git and create symbolic link in the directory.
~~~
w3const@a012
git clone https://github.com/ddbj/mssassist.git ~/mssassist → see NOTE!
  Note! Do NOT change the destition name for installing the mssassist. When you would like to change the directory name from 'mssassist', you should change the value of $BASE variable in each shell script.
 ↓
cd ~/mssassist
ln -s ddbj_autofix.sh ddbj_autofix
ln -s ddbj_kaeru.sh ddbj_kaeru
ln -s sing_ddbj_mss_validation.sh ddbj_mss_validation
ln -s ddbj_sakura2DB.sh ddbj_sakura2DB
~~~

2. Create 'tables' directory
~~~
w3const@a012:~/mssassist$ mkdir -m 775 tables
~~~
Data files required to run MSS validation tools are prepared here.

3. Add the followings to cron@a012
~~~
# MSS ddbj_mss_validation
0 8 * * *  bash /home/w3const/mssassist/update_taxdump.sh
0 8,10,12,14,16,18 * * * bash /home/w3const/mssassist/update_tables.sh
~~~
