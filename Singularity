Bootstrap: docker
From: ubuntu:24.04

# path
%environment
    export PATH=/opt:$PATH
    export LANG=en_US.UTF8

%setup
    echo "Started to create singularity sif file for MssAssist" > /dev/null

%files

%runscript

%post
    apt update
    apt -y upgrade
    DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
    ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime    
    dpkg-reconfigure --frontend noninteractive tzdata
    apt -y install language-pack-en
    update-locale LANG=en_US.UTF-8
    # apt -y install r-base python3-minimal python3-pip python3-pandas python3-numpy python3-oauth2client
    apt -y install build-essential wget curl python3-minimal python3-pip r-base r-recommended
    pip3 install oauth2client pandas numpy gspread --break-system-packages
    # Do NOT change the order
    Rscript -e 'install.packages("fedmatch", repos="https://cloud.r-project.org")'
    Rscript -e 'install.packages("tidyr", repos="https://cloud.r-project.org")'
    Rscript -e 'install.packages("doParallel", repos="https://cloud.r-project.org")'
    Rscript -e 'install.packages(c("colorspace", "fansi", "munsell"), repos="https://cloud.r-project.org")'

%labels
    Author tkosuge@nig
    Version 2025-07-10

%help
    This file is Singularity definition for offering python, R and their libraries to completely run MSS assist tools (Andrea-san tool).
