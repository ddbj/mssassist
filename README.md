# mssassist
Validation, correction, and data registration scripts to assist MSS work

I have taken Andrea-san mss fix tools, and will migrate them here.
Takehide Kosuge

# Installation
1. Ssh loogin to a012 as w3const user.
1. Pull the repository from ddbj/mssassist.git and create symbolic link in the directory.
    ~~~
    git clone https://github.com/ddbj/mssassist.git ~/mssassist
    ~~~
    Note! Do NOT change the destition directory for installing the mssassist. When you would like to change the directory name from 'mssassist',       you should change the value of $BASE variable in each shell script.
     ↓
    ~~~
    cd ~/mssassist
    ln -s ddbj_autofix.sh ddbj_autofix
    ln -s ddbj_kaeru.sh ddbj_kaeru
    ln -s sing_ddbj_mss_validation.sh ddbj_mss_validation
    ln -s ddbj_sakura2DB.sh ddbj_sakura2DB
    ~~~
1. Create 'tables' directory
    ~~~
    mkdir -m 775 tables
    ~~~
    Data files required to run MSS validation tools are prepared here.
1. Add the followings to cron@a012
    ~~~
    # MSS ddbj_mss_validation
    0 8 * * *  bash /home/w3const/mssassist/update_taxdump.sh
    0 8,10,12,14,16,18 * * * bash /home/w3const/mssassist/update_tables.sh
    ~~~

# How to use
コマンド使用方法は、Confluenceの「MSS 査定; 新規登録の作業手順」ページを参照。
