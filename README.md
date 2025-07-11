# mssassist
Validation, correction, and data registration scripts to assist MSS work

I (tkosuge) have taken Andrea-san mss fix tools, and will have migrated them here. You can see the overview of the tools [from here](https://github.com/ddbj/ddbj_curator_assistant/blob/main/README.md#mass-dataset-documentation).

# Installation
1. Ssh login to a012 node as w3const user.
1. Pull the repository from ddbj/mssassist.git.
    ~~~
    git clone https://github.com/ddbj/mssassist.git ~/mssassist
    ~~~
    Note! Do NOT change the destination directory for installing the mssassist. When you would like to change the directory name from 'mssassist',       you need to change the value of $BASE variable in each shell script.
1. Prepare the symbolic link in the directory.
    ~~~
    cd ~/mssassist
    ln -s ddbj_autofix.sh ddbj_autofix
    ln -s ddbj_kaeru.sh ddbj_kaeru
    ln -s sing_ddbj_mss_validation.sh ddbj_mss_validation
    ln -s ddbj_sakura2DB.sh ddbj_sakura2DB
    ~~~
1. Create 'tables' directory.
    ~~~
    mkdir -m 775 tables
    ~~~
    Data files required to run MSS validation tools are created here.
1. Put the JSON type API keyfile to write MSSworking gsheet in .key directory.
   ~~~
   mkdir -m 750 .key
   And copy the ######.json file to .key/ directory, and then set the permission to 640.
   ~~~
1. Add the followings to cron@a012.
    ~~~
    # MSS ddbj_mss_validation
    0 8 * * *  bash /home/w3const/mssassist/update_taxdump.sh
    0,10,20,30,40,50 8-19 * * * bash /home/w3const/mssassist/update_tables.sh
    ~~~
1. Prepare the singularity sif container required for running R/Python scripts stored in step#/ directories.
   ~~~
   # Login to ddbjs1 workstation or anohter appropriate server where users can build singularity containers.
   # Execute the following command.
   sudo singularity build sing-mssassist.sif ./Singularity
   
   # Upload the sing-mssassist.sif to /home/w3const/mssassist directory 
   ~~~

# How to use
- jParser、transCheckerを使用可能な環境で実行する。
- w3constにsshでアクセスできるようにしておく。
- コマンド使用方法は、Confluenceの「MSS 査定; 新規登録の作業手順」ページを参照。

# Links
- [移行のために行った解析結果(Ctrl+Click to open in new tab)][mss validation tools解析]

[mss validation tools解析]:https://docs.google.com/document/d/1qdvaYgYwO0oA49H1lJf_P16XcGtYWAWD7XbIltqimm8/edit?pli=1&tab=t.0#heading=h.bbg6c1jm8mfl

